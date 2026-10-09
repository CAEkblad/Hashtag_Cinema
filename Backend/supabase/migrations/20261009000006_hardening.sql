-- Column level write limits. Row level security says whose rows; these say
-- which columns the app may change. Credits, roles, partner status, payments
-- and edit status only change through Edge Functions or security definer functions.

revoke insert, update on profiles from anon, authenticated;
grant update (name, market, niche, city_id, service_area_ids, goals, weekly_goal, team_name, also_sells, shares_with_office)
  on profiles to authenticated;

revoke insert, update on clips from anon, authenticated;
grant update (title, is_favorite) on clips to authenticated;

revoke insert, update on bookings from anon, authenticated;
grant update (notes, address) on bookings to authenticated;

revoke insert, update on posts from anon, authenticated;

revoke update on leads from anon, authenticated;
grant update (status) on leads to authenticated;

revoke insert, update, delete on purchases, revenue_share_ledger, edit_jobs, webhook_events, social_accounts from anon, authenticated;
grant update (stage, transcript) on edit_jobs to authenticated;   -- editors move their own jobs (RLS limits rows)

revoke update on community_posts from anon, authenticated;
grant update (body) on community_posts to authenticated;
create policy "edit own community posts" on community_posts for update using (author_id = auth.uid());
