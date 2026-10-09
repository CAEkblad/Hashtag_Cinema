"""Builds the Florida market dataset used by the app and the backend.

Inputs (in the folder passed as argv[1]):
  geonames_fl.json  Florida populated places (GeoNames via the all-the-cities npm package)
  us_cities.csv     US places with county names (kelvins/US-Cities-Database)

Outputs:
  Cinema/Data/florida_cities.json       bundled in the iOS app
  Backend/supabase/migrations/20261009000004_florida_cities.sql

Run:  python3 Backend/tools/build_florida_cities.py <data folder>
"""
import csv
import json
import math
import re
import sys
from pathlib import Path

DATA = Path(sys.argv[1])
ROOT = Path(__file__).resolve().parents[2]

COUNTIES = [
    "Alachua", "Baker", "Bay", "Bradford", "Brevard", "Broward", "Calhoun", "Charlotte", "Citrus", "Clay",
    "Collier", "Columbia", "DeSoto", "Dixie", "Duval", "Escambia", "Flagler", "Franklin", "Gadsden", "Gilchrist",
    "Glades", "Gulf", "Hamilton", "Hardee", "Hendry", "Hernando", "Highlands", "Hillsborough", "Holmes",
    "Indian River", "Jackson", "Jefferson", "Lafayette", "Lake", "Lee", "Leon", "Levy", "Liberty", "Madison",
    "Manatee", "Marion", "Martin", "Miami-Dade", "Monroe", "Nassau", "Okaloosa", "Okeechobee", "Orange",
    "Osceola", "Palm Beach", "Pasco", "Pinellas", "Polk", "Putnam", "St. Johns", "St. Lucie", "Santa Rosa",
    "Sarasota", "Seminole", "Sumter", "Suwannee", "Taylor", "Union", "Volusia", "Wakulla", "Walton", "Washington",
]
assert len(COUNTIES) == 67

REGIONS = {
    "tampaBay": ["Hillsborough", "Pinellas", "Pasco", "Hernando"],
    "suncoast": ["Manatee", "Sarasota"],
    "southwest": ["Charlotte", "Lee", "Collier", "Hendry", "Glades", "DeSoto"],
    "southFlorida": ["Miami-Dade", "Broward", "Palm Beach"],
    "keys": ["Monroe"],
    "treasureCoast": ["Martin", "St. Lucie", "Indian River", "Okeechobee"],
    "spaceCoast": ["Brevard"],
    "centralFlorida": ["Orange", "Seminole", "Osceola", "Lake", "Sumter"],
    "heartland": ["Polk", "Highlands", "Hardee"],
    "natureCoast": ["Citrus", "Levy", "Dixie", "Taylor"],
    "northCentral": ["Alachua", "Marion", "Columbia", "Gilchrist", "Union", "Bradford", "Putnam", "Suwannee", "Lafayette", "Hamilton"],
    "daytonaFlagler": ["Volusia", "Flagler"],
    "firstCoast": ["Duval", "St. Johns", "Clay", "Nassau", "Baker"],
    "bigBend": ["Leon", "Gadsden", "Wakulla", "Jefferson", "Madison", "Liberty", "Franklin"],
    "panhandle": ["Escambia", "Santa Rosa", "Okaloosa", "Walton", "Bay", "Washington", "Holmes", "Jackson", "Calhoun", "Gulf"],
}
REGION_OF = {county: region for region, counties in REGIONS.items() for county in counties}
assert sorted(REGION_OF) == sorted(COUNTIES), set(COUNTIES) ^ set(REGION_OF)

COASTAL = {
    "Nassau", "Duval", "St. Johns", "Flagler", "Volusia", "Brevard", "Indian River", "St. Lucie", "Martin",
    "Palm Beach", "Broward", "Miami-Dade", "Monroe", "Collier", "Lee", "Charlotte", "Sarasota", "Manatee",
    "Hillsborough", "Pinellas", "Pasco", "Hernando", "Citrus", "Levy", "Dixie", "Taylor", "Jefferson", "Wakulla",
    "Franklin", "Gulf", "Bay", "Walton", "Okaloosa", "Santa Rosa", "Escambia",
}
LAKE_COUNTIES = {"Orange", "Seminole", "Osceola", "Lake", "Polk", "Highlands", "Marion", "Alachua", "Putnam"}


def county_key(raw: str) -> str:
    s = raw.strip().lower().replace("saint ", "st. ").replace("-", " ")
    return re.sub(r"\s+", " ", s)


COUNTY_BY_KEY = {county_key(c): c for c in COUNTIES}
COUNTY_BY_KEY["de soto"] = "DeSoto"
COUNTY_BY_KEY["desoto"] = "DeSoto"


def name_key(raw: str) -> str:
    s = raw.lower().replace("saint ", "st. ").replace("st ", "st. ").replace("'", "")
    return re.sub(r"[^a-z0-9. ]", "", s).strip()


# ---------------------------------------------------------------- curated
def tagged(names, trait):
    return {n: trait for n in names}


TRAITS = {}


def add(trait, names):
    for n in names:
        TRAITS.setdefault(n, set()).add(trait)


add("beach", [
    "Destin", "Clearwater", "Siesta Key", "Naples", "Key West", "Marco Island", "Sanibel", "St. Augustine",
    "Navarre", "Gulf Breeze", "Treasure Island", "Indian Rocks Beach", "Anna Maria", "Longboat Key", "Venice",
    "Englewood", "Boca Grande", "Captiva", "Jupiter", "Stuart", "Fort Lauderdale", "Hollywood", "Key Biscayne",
    "Islamorada", "Marathon", "Key Largo", "Indian Shores", "Belleair Beach", "Sunny Isles Beach", "Hallandale Beach",
    "Lauderdale-by-the-Sea", "Satellite Beach", "Indialantic", "Melbourne Beach", "St. Augustine Beach",
    "Santa Rosa Beach", "Rosemary Beach", "Miramar Beach", "Mexico Beach", "Port St. Joe", "Cape Canaveral",
    "Ormond Beach", "Flagler Beach", "Vero Beach", "Fort Pierce", "Palm Beach", "Boca Raton", "Delray Beach",
    "Juno Beach", "Tequesta", "Bonita Springs", "Fort Myers Beach", "Pensacola", "Bal Harbour", "Surfside",
    "Fisher Island", "Holmes Beach", "Bradenton Beach", "Nokomis", "Osprey", "Dunedin", "Madeira Beach",
])
add("boating", [
    "Cape Coral", "Fort Lauderdale", "Punta Gorda", "Port Charlotte", "Stuart", "Islamorada", "Key Largo", "Marathon",
    "Tarpon Springs", "Destin", "Apalachicola", "Naples", "Fort Myers", "Venice", "Jupiter", "Palm Beach Gardens",
    "Englewood", "Clearwater", "St. Petersburg", "Tampa", "Apollo Beach", "Ruskin", "Gulf Breeze", "Panama City",
    "Crystal River", "Homosassa", "Steinhatchee", "Cedar Key", "Merritt Island", "Key West", "Marco Island",
    "Palmetto", "Bradenton", "Sarasota", "North Palm Beach", "Lighthouse Point", "Pompano Beach", "Boca Raton",
    "Hollywood", "Miami Beach", "Coral Gables", "Hernando Beach", "New Port Richey", "Port Richey", "Titusville",
    "Fernandina Beach", "Jacksonville", "Palm Coast", "Sebastian", "Port Orange", "New Smyrna Beach", "Bonita Springs",
])
add("golf", [
    "Ponte Vedra Beach", "Palm Beach Gardens", "Naples", "Lakewood Ranch", "The Villages", "Bonita Springs", "Jupiter",
    "Davenport", "St. Augustine", "Weston", "Doral", "Palm Coast", "Sun City Center", "Port St. Lucie", "Miramar Beach",
    "Fernandina Beach", "Howey-in-the-Hills", "Sebring", "Orlando", "Windermere", "Estero", "Wellington", "Boca Raton",
    "Trinity", "Lutz", "Brooksville", "Destin", "Palm Harbor", "Bradenton", "Sarasota", "Lady Lake", "Fruitland Park",
])
add("retirement", [
    "The Villages", "Sun City Center", "Lady Lake", "Wildwood", "Fruitland Park", "Leesburg", "Venice", "Englewood",
    "Punta Gorda", "Port Charlotte", "North Port", "Sebring", "Avon Park", "Lake Placid", "Zephyrhills", "Spring Hill",
    "Homosassa Springs", "Inverness", "Beverly Hills", "Ocala", "Dunnellon", "Bonita Springs", "Naples", "Largo",
    "Seminole", "Pinellas Park", "Dunedin", "Leisure City", "Kings Point", "Century Village", "Delray Beach",
    "Boynton Beach", "Port St. Lucie", "Vero Beach", "Palm Coast", "Ormond Beach", "New Port Richey", "Hudson",
    "Tavares", "Mount Dora", "Eustis", "Clermont", "Lakewood Ranch", "Estero", "Fort Myers", "Lehigh Acres",
])
add("snowbird", [
    "Naples", "Fort Myers", "Fort Myers Beach", "Sarasota", "Venice", "Punta Gorda", "Clearwater", "Largo", "Dunedin",
    "Englewood", "Bradenton", "Vero Beach", "Sebring", "Bonita Springs", "Marco Island", "Sanibel", "Key West",
    "Palm Beach", "Boca Raton", "Delray Beach", "Fort Lauderdale", "Pompano Beach", "Hollywood", "Hallandale Beach",
    "Sunny Isles Beach", "Daytona Beach", "Ormond Beach", "New Smyrna Beach", "St. Petersburg", "Treasure Island",
    "Madeira Beach", "Indian Rocks Beach", "Port Charlotte", "Cape Coral", "Estero", "Zephyrhills", "Lakeland",
    "Winter Haven", "Mount Dora", "The Villages", "Siesta Key", "Longboat Key", "Anna Maria", "Holmes Beach",
    "Stuart", "Jupiter", "Islamorada", "Marathon", "Key Largo", "Cocoa Beach", "Melbourne",
])
add("college", [
    "Gainesville", "Tallahassee", "Tampa", "Orlando", "Boca Raton", "Coral Gables", "Miami", "Sweetwater", "Estero",
    "Fort Myers", "Pensacola", "DeLand", "Melbourne", "Daytona Beach", "Lakeland", "Winter Park", "Sarasota",
    "Jacksonville", "St. Petersburg", "Davie", "Miami Gardens", "Fort Lauderdale", "Ave Maria", "University Park",
])
add("military", [
    "Pensacola", "Fort Walton Beach", "Niceville", "Valparaiso", "Crestview", "Mary Esther", "Panama City",
    "Tampa", "Jacksonville", "Atlantic Beach", "Key West", "Homestead", "Milton", "Satellite Beach", "Melbourne",
    "Cocoa Beach", "Orange Park", "Fleming Island", "Navarre", "Lynn Haven", "Callaway", "Gulf Breeze",
])
add("themeParks", [
    "Orlando", "Kissimmee", "Celebration", "Lake Buena Vista", "Davenport", "Winter Garden", "Windermere",
    "Horizon West", "Four Corners", "Clermont", "Haines City", "Tampa", "Winter Haven", "Dr. Phillips",
])
add("historic", [
    "St. Augustine", "Fernandina Beach", "Key West", "Mount Dora", "Apalachicola", "Pensacola", "Ybor City",
    "Tarpon Springs", "Micanopy", "Cedar Key", "DeLand", "Sanford", "Winter Park", "Coral Gables", "Lake Wales",
    "Dade City", "Brooksville", "Arcadia", "Monticello", "Quincy", "Fort Myers", "Fort Pierce", "Lakeland", "Ocala",
])
add("luxury", [
    "Palm Beach", "Naples", "Boca Raton", "Jupiter", "Coral Gables", "Key Biscayne", "Fisher Island", "Miami Beach",
    "Longboat Key", "Ponte Vedra Beach", "Windermere", "Destin", "Rosemary Beach", "Bal Harbour", "Sanibel",
    "Captiva", "Boca Grande", "Golden Beach", "Indian Creek", "Pinecrest", "Palm Beach Gardens", "Manalapan",
    "Gulf Stream", "Isleworth", "Siesta Key", "Marco Island", "Wellington", "Winter Park", "Belleair",
    "Sunny Isles Beach", "Fort Lauderdale", "Vero Beach", "Santa Rosa Beach", "Miramar Beach", "Anna Maria",
    "Weston", "Parkland", "Southwest Ranches", "Lakewood Ranch", "Davis Islands", "Tequesta", "North Palm Beach",
])
add("growth", [
    "Wesley Chapel", "Riverview", "Lakewood Ranch", "St. Cloud", "Poinciana", "Clermont", "Palm Bay", "Port St. Lucie",
    "Lehigh Acres", "North Port", "Ocala", "Haines City", "Davenport", "Wildwood", "Nocatee", "Land O' Lakes",
    "Zephyrhills", "Apopka", "Groveland", "Minneola", "Winter Garden", "Horizon West", "Parrish", "Ruskin",
    "Wimauma", "Plant City", "Lakeland", "Winter Haven", "Kissimmee", "Cape Coral", "Fort Myers", "Estero",
    "Ave Maria", "Immokalee", "Palm Coast", "Deltona", "Daytona Beach", "St. Johns", "Fruit Cove", "Yulee",
    "Green Cove Springs", "Middleburg", "Crestview", "Panama City Beach", "Navarre", "Pace", "Spring Hill",
    "Brooksville", "Bartow", "Auburndale", "Lake Wales", "Viera", "Melbourne", "Sanford", "Lake Mary", "Oviedo",
    "Mascotte", "Leesburg", "Tavares", "Sebastian", "Punta Gorda", "Port Charlotte", "Englewood", "Venice",
])
add("condos", [
    "Miami", "Miami Beach", "Sunny Isles Beach", "Fort Lauderdale", "Clearwater", "St. Petersburg", "Sarasota",
    "Naples", "Marco Island", "Destin", "Panama City Beach", "Hollywood", "Hallandale Beach", "Aventura",
    "Jacksonville Beach", "Daytona Beach", "Daytona Beach Shores", "New Smyrna Beach", "Palm Beach", "Boca Raton",
    "Tampa", "Orlando", "Treasure Island", "Indian Shores", "Cocoa Beach", "Riviera Beach", "Fort Myers Beach",
    "Bonita Springs", "Pompano Beach", "Lauderdale-by-the-Sea", "Bal Harbour", "Key Biscayne", "Longboat Key",
    "Madeira Beach", "West Palm Beach", "Fort Myers", "Doral", "Brickell", "Bay Harbor Islands", "North Miami Beach",
])
add("equestrian", ["Ocala", "Wellington", "Loxahatchee", "Southwest Ranches", "Davie", "Reddick", "Williston", "Archer", "Brooksville", "Myakka City", "Parrish"])
add("space", ["Titusville", "Cocoa Beach", "Merritt Island", "Cape Canaveral", "Cocoa", "Rockledge", "Viera", "Melbourne", "Palm Bay", "Satellite Beach"])
add("shortTermRental", ["Kissimmee", "Davenport", "Destin", "Panama City Beach", "Miramar Beach", "Santa Rosa Beach", "Key West", "Clearwater", "Fort Myers Beach", "Siesta Key", "Anna Maria", "Holmes Beach", "St. Augustine Beach", "Daytona Beach", "New Smyrna Beach", "Cocoa Beach", "Navarre", "Four Corners", "Celebration", "Marathon", "Islamorada"])

HIGHLIGHTS = {
    "Dunedin": ["Toronto Blue Jays spring training"],
    "Clearwater": ["Philadelphia Phillies spring training", "Clearwater Beach"],
    "Tampa": ["New York Yankees spring training", "Gasparilla Pirate Festival in late January", "Bayshore Boulevard and the Riverwalk", "MacDill Air Force Base"],
    "Lakeland": ["Detroit Tigers spring training", "Lake Mirror and historic downtown"],
    "Bradenton": ["Pittsburgh Pirates spring training"],
    "Sarasota": ["Baltimore Orioles spring training", "Arts and culture scene", "Minutes to Siesta Key and Lido Key"],
    "North Port": ["Atlanta Braves spring training", "Fast growing new construction"],
    "Port Charlotte": ["Tampa Bay Rays spring training"],
    "Fort Myers": ["Boston Red Sox and Minnesota Twins spring training", "Historic river district"],
    "Jupiter": ["St. Louis Cardinals and Miami Marlins spring training", "Jupiter Lighthouse and inlet"],
    "West Palm Beach": ["Houston Astros and Washington Nationals spring training", "Clematis Street and the waterfront"],
    "Port St. Lucie": ["New York Mets spring training"],
    "St. Petersburg": ["Waterfront downtown, the Pier and museums", "Sunshine City"],
    "Orlando": ["Theme park capital of the world", "Lake Nona and its medical city", "University of Central Florida"],
    "Kissimmee": ["Minutes from Walt Disney World", "Vacation and short term rental homes"],
    "Celebration": ["Disney-built town with a walkable downtown"],
    "Daytona Beach": ["Daytona 500 in February", "Bike Week in March", "Embry-Riddle Aeronautical University"],
    "Plant City": ["Florida Strawberry Festival in late winter"],
    "Ocala": ["Horse Capital of the World", "World Equestrian Center"],
    "Wellington": ["Winter Equestrian Festival"],
    "St. Augustine": ["Nation's oldest city", "Nights of Lights each winter"],
    "Key West": ["Southernmost point in the continental US", "Fantasy Fest in October", "Duval Street"],
    "Miami Beach": ["Art Basel Miami Beach in December", "South Beach and Art Deco district"],
    "Miami": ["Brickell skyline and international buyers", "Wynwood walls"],
    "Gainesville": ["University of Florida and game day weekends"],
    "Tallahassee": ["State capital", "Florida State University and FAMU"],
    "Pensacola": ["Naval Air Station Pensacola, home of the Blue Angels", "Pensacola Beach"],
    "Cocoa Beach": ["Rocket launch views", "Surf town"],
    "Titusville": ["Front row seat to Kennedy Space Center launches"],
    "Merritt Island": ["Kennedy Space Center next door"],
    "The Villages": ["One of the largest 55+ communities in the country", "Golf cart lifestyle"],
    "Naples": ["Fifth Avenue South and Third Street South", "Gulf sunsets and the Naples Pier"],
    "Cape Coral": ["Hundreds of miles of canals", "Gulf access homes"],
    "Fort Lauderdale": ["Venice of America with miles of canals", "Las Olas Boulevard"],
    "Winter Park": ["Park Avenue shops", "Rollins College"],
    "Mount Dora": ["Antique shops and festivals", "Lake Dora"],
    "Destin": ["World's Luckiest Fishing Village", "Emerald Coast beaches"],
    "Panama City Beach": ["27 miles of beach", "Pier Park"],
    "Tarpon Springs": ["Greek heritage and the sponge docks"],
    "Apalachicola": ["Old Florida fishing town"],
    "Crystal River": ["Swim with manatees"],
    "Lakewood Ranch": ["One of the top selling master planned communities in the US"],
    "Jacksonville": ["Largest city by area in the contiguous US", "Naval Station Mayport and NAS Jacksonville"],
    "Homestead": ["Gateway to Everglades and Biscayne National Parks", "Homestead Air Reserve Base"],
    "Fort Walton Beach": ["Next to Eglin Air Force Base and Hurlburt Field"],
    "Niceville": ["Next to Eglin Air Force Base"],
    "Crestview": ["Growing military family market near Eglin"],
    "Panama City": ["Tyndall Air Force Base"],
    "Melbourne": ["Patrick Space Force Base nearby", "Florida Tech"],
    "Boca Raton": ["Florida Atlantic University", "Mizner Park"],
    "Coral Gables": ["University of Miami", "Miracle Mile"],
    "DeLand": ["Stetson University", "Historic downtown"],
    "Ponte Vedra Beach": ["TPC Sawgrass, home of THE PLAYERS"],
    "Palm Beach": ["Worth Avenue"],
    "Delray Beach": ["Atlantic Avenue nightlife"],
    "Venice": ["Shark Tooth Capital of the World"],
    "Siesta Key": ["Quartz sand beach"],
    "Sanibel": ["Shelling beaches"],
    "Winter Haven": ["Chain of lakes"],
    "Sebring": ["12 Hours of Sebring race"],
    "Fernandina Beach": ["Amelia Island and its historic downtown"],
    "Weston": ["Top rated schools and master planned neighborhoods"],
    "Doral": ["Business hub near Miami International Airport"],
    "Wesley Chapel": ["New construction and Tampa Premium Outlets"],
    "Riverview": ["New construction communities south of Tampa"],
    "St. Cloud": ["Lakefront downtown and new construction"],
    "Palm Coast": ["Saltwater canals and golf"],
    "Lake Mary": ["Corporate hub north of Orlando"],
}

NEIGHBORHOODS = {
    "Tampa": ["South Tampa", "Hyde Park", "Seminole Heights", "Davis Islands", "Westchase", "New Tampa", "Channel District", "Ybor City", "Palma Ceia", "Carrollwood"],
    "St. Petersburg": ["Old Northeast", "Downtown", "Kenwood", "Snell Isle", "Shore Acres", "Crescent Lake", "Grand Central", "Placido Bayou"],
    "Orlando": ["Lake Nona", "Baldwin Park", "College Park", "Thornton Park", "Dr. Phillips", "Audubon Park", "Lake Eola Heights", "MetroWest"],
    "Miami": ["Brickell", "Wynwood", "Coconut Grove", "Little Havana", "Edgewater", "Design District", "Upper East Side", "Little River"],
    "Jacksonville": ["Riverside", "Avondale", "San Marco", "Mandarin", "Southside", "Ortega", "Springfield", "Baymeadows"],
    "Fort Lauderdale": ["Las Olas", "Victoria Park", "Coral Ridge", "Rio Vista", "Flagler Village", "Harbor Beach"],
    "Naples": ["Old Naples", "Park Shore", "Pelican Bay", "Port Royal", "Vanderbilt Beach", "Olde Cypress"],
    "Sarasota": ["Downtown", "Lido Key", "Siesta Key", "Palmer Ranch", "Southside Village", "Bird Key", "Laurel Park"],
    "Tallahassee": ["Midtown", "Killearn", "SouthWood", "Betton Hills", "Lafayette Park"],
    "Gainesville": ["Duckpond", "Haile Plantation", "Downtown", "Tioga", "Northwest Gainesville"],
    "Pensacola": ["East Hill", "North Hill", "Downtown", "Cordova Park", "Pensacola Beach"],
    "Cape Coral": ["Southwest Cape", "Yacht Club", "Cape Harbour", "Pelican", "Northwest Cape"],
    "Clearwater": ["Clearwater Beach", "Island Estates", "Countryside", "Downtown"],
    "Fort Myers": ["McGregor Boulevard", "River District", "Gateway", "Whiskey Creek"],
    "West Palm Beach": ["El Cid", "Flamingo Park", "Northwood", "Downtown"],
    "Boca Raton": ["Royal Palm Yacht and Country Club", "Downtown Boca", "Boca West", "Mizner Park"],
    "Lakeland": ["Dixieland", "Lake Morton", "South Lakeland", "Lake Hollingsworth"],
    "Bradenton": ["Downtown", "Palma Sola", "Village of the Arts", "Northwest Bradenton"],
    "Daytona Beach": ["Beachside", "LPGA", "Downtown Daytona"],
    "St. Augustine": ["Lincolnville", "Davis Shores", "Downtown historic district", "Vilano Beach"],
    "Kissimmee": ["Downtown Kissimmee", "Champions Gate", "Reunion", "Celebration area"],
    "Winter Park": ["Park Avenue", "Windsong", "Olde Winter Park"],
    "Coral Gables": ["Old Cutler", "Cocoplum", "The Biltmore area", "Miracle Mile"],
    "Hollywood": ["Hollywood Lakes", "Downtown Hollywood", "Emerald Hills", "Hollywood Beach"],
    "Port St. Lucie": ["Tradition", "St. Lucie West", "Torino"],
    "Palm Bay": ["Bayside Lakes", "Northeast Palm Bay"],
    "Ocala": ["Historic district", "Golden Ocala", "On Top of the World", "SW Ocala"],
    "Destin": ["Crystal Beach", "Holiday Isle", "Destin Harbor", "Kelly Plantation"],
    "Wesley Chapel": ["Epperson", "Wiregrass Ranch", "Meadow Pointe", "Seven Oaks"],
    "Riverview": ["Waterleaf", "South Fork", "Panther Trace", "Boyette"],
    "Lakewood Ranch": ["Waterside", "Country Club", "Lakewood Ranch Main Street"],
    "The Villages": ["Spanish Springs", "Lake Sumter Landing", "Brownwood"],
}

MANUAL_PLACES = [
    {"name": "Lakewood Ranch", "county": "Manatee", "lat": 27.4026, "lon": -82.4004, "pop": 34877},
    {"name": "Santa Rosa Beach", "county": "Walton", "lat": 30.3960, "lon": -86.2288, "pop": None},
    {"name": "Rosemary Beach", "county": "Walton", "lat": 30.2788, "lon": -86.0158, "pop": None},
    {"name": "Boca Grande", "county": "Lee", "lat": 26.7498, "lon": -82.2618, "pop": None},
    {"name": "Captiva", "county": "Lee", "lat": 26.5220, "lon": -82.1912, "pop": None},
    {"name": "Fisher Island", "county": "Miami-Dade", "lat": 25.7607, "lon": -80.1428, "pop": None},
]

# ---------------------------------------------------------------- load
geo = json.loads((DATA / "geonames_fl.json").read_text())

postal = []
with open(DATA / "us_cities.csv", newline="") as f:
    for row in csv.DictReader(f):
        if row["STATE_CODE"] != "FL" or not row["COUNTY"].strip():
            continue
        county = COUNTY_BY_KEY.get(county_key(row["COUNTY"]))
        if not county:
            continue
        postal.append((name_key(row["CITY"]), county, float(row["LATITUDE"]), float(row["LONGITUDE"])))


def dist(lat1, lon1, lat2, lon2):
    dx = (lon1 - lon2) * math.cos(math.radians((lat1 + lat2) / 2))
    return math.hypot(lat1 - lat2, dx)


def county_for(name, lat, lon):
    key = name_key(name)
    matches = [p for p in postal if p[0] == key]
    pool = matches if matches else postal
    best = min(pool, key=lambda p: dist(lat, lon, p[2], p[3]))
    if matches and dist(lat, lon, best[2], best[3]) > 0.35:
        best = min(postal, key=lambda p: dist(lat, lon, p[2], p[3]))
    return best[1]


def canonical(name):
    n = name.replace("Saint ", "St. ")
    return {"Port Saint Lucie": "Port St. Lucie", "Doctor Phillips": "Dr. Phillips"}.get(n, n)


places = []
for g in geo:
    if g["code"] == "PPLX":
        continue
    name = canonical(g["name"])
    places.append({"name": name, "county": county_for(g["name"], g["lat"], g["lon"]), "lat": g["lat"], "lon": g["lon"], "pop": g["pop"]})
for m in MANUAL_PLACES:
    if not any(p["name"] == m["name"] for p in places):
        places.append(dict(m))

# Dedupe same name in the same county.
seen = {}
for p in places:
    k = (p["name"], p["county"])
    if k not in seen or (p["pop"] or 0) > (seen[k]["pop"] or 0):
        seen[k] = p
places = list(seen.values())

# Drop tiny duplicates of a big city's name in a neighboring county (data artifacts).
by_name = {}
for p in places:
    by_name.setdefault(p["name"], []).append(p)
places = [
    p for p in places
    if not any(o is not p and (o["pop"] or 0) > 50_000 and (p["pop"] or 0) < 5_000 for o in by_name[p["name"]])
]


def slug(s):
    return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")


def trait_lookup(name):
    alias = name.replace("St. ", "Saint ")
    return TRAITS.get(name, set()) | TRAITS.get(alias, set())


out = []
for p in places:
    county = p["county"]
    traits = set(trait_lookup(p["name"]))
    name = p["name"]
    if county in COASTAL:
        traits.add("coastalCounty")
        if re.search(r"\bBeach\b|\bKey\b|\bIsland\b|\bShores\b", name):
            traits.add("beach")
    if county in LAKE_COUNTIES:
        traits.add("lakes")
    pop = p["pop"]
    if pop and pop >= 150_000:
        traits.add("urban")
    elif pop and pop >= 25_000:
        traits.add("suburban")
    else:
        traits.add("smallTown")
    out.append({
        "id": f"{slug(name)}-{slug(county)}",
        "name": name,
        "county": county,
        "region": REGION_OF[county],
        "population": pop,
        "lat": round(p["lat"], 4),
        "lon": round(p["lon"], 4),
        "traits": sorted(traits),
        "highlights": HIGHLIGHTS.get(name, []),
        "neighborhoods": NEIGHBORHOODS.get(name, []),
    })

out.sort(key=lambda c: (-(c["population"] or 0), c["name"]))
ids = [c["id"] for c in out]
assert len(ids) == len(set(ids)), "duplicate ids"

missing_curated = sorted(set(HIGHLIGHTS) - {c["name"] for c in out})
missing_hoods = sorted(set(NEIGHBORHOODS) - {c["name"] for c in out})
print("cities:", len(out), "| highlights not matched:", missing_curated, "| neighborhoods not matched:", missing_hoods)

app_json = ROOT / "Cinema" / "Data" / "florida_cities.json"
app_json.write_text(json.dumps(out, separators=(",", ":"), ensure_ascii=False))

seed = ROOT / "Backend" / "supabase" / "migrations" / "20261009000004_florida_cities.sql"
seed.parent.mkdir(parents=True, exist_ok=True)


def q(s):
    return "null" if s is None else "'" + str(s).replace("'", "''") + "'"


def arr(items):
    return "array[" + ",".join(q(i) for i in items) + "]::text[]" if items else "'{}'::text[]"


lines = [
    "-- Generated by Backend/tools/build_florida_cities.py. Do not edit by hand.",
    "insert into cities (id, name, state, county, region, population, lat, lng, traits, highlights, neighborhoods) values",
]
rows = []
for c in out:
    rows.append(
        f"({q(c['id'])},{q(c['name'])},'FL',{q(c['county'])},{q(c['region'])},"
        f"{c['population'] if c['population'] else 'null'},{c['lat']},{c['lon']},"
        f"{arr(c['traits'])},{arr(c['highlights'])},{arr(c['neighborhoods'])})"
    )
lines.append(",\n".join(rows))
lines.append("on conflict (id) do update set name = excluded.name, county = excluded.county, region = excluded.region,")
lines.append("  population = excluded.population, lat = excluded.lat, lng = excluded.lng, traits = excluded.traits,")
lines.append("  highlights = excluded.highlights, neighborhoods = excluded.neighborhoods;")
seed.write_text("\n".join(lines) + "\n")
print("wrote", app_json.relative_to(ROOT), "and", seed.relative_to(ROOT))
