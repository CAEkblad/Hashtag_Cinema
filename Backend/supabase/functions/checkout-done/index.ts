// Page Stripe shows after checkout. Sends people back to the app. Deploy with --no-verify-jwt.
Deno.serve((req) => {
  const status = new URL(req.url).searchParams.get("status") === "success" ? "success" : "cancel";
  const title = status === "success" ? "You're all set" : "Checkout canceled";
  const message = status === "success"
    ? "Payment received. Your booking or credits update in the app within a minute."
    : "No charge was made. You can try again from the app.";
  const html = `<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1">
<title>#Cinema</title><style>body{font-family:-apple-system,system-ui,sans-serif;background:#F6F6F8;color:#141416;display:flex;min-height:100vh;align-items:center;justify-content:center;margin:0}
main{background:#fff;border-radius:18px;padding:32px;max-width:360px;text-align:center;box-shadow:0 4px 20px rgba(0,0,0,.06)}
h1{font-size:24px;margin:0 0 8px}p{color:#5C5C66}a{display:inline-block;margin-top:16px;background:#E11D2E;color:#fff;padding:14px 22px;border-radius:999px;text-decoration:none;font-weight:600}</style></head>
<body><main><h1>${title}</h1><p>${message}</p><a href="hashtagcinema://checkout/${status}">Back to #Cinema</a></main></body></html>`;
  return new Response(html, { headers: { "Content-Type": "text/html; charset=utf-8" } });
});
