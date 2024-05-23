const { defineConfig } = require("cypress");

module.exports = defineConfig({
  e2e: {
      baseUrl: 'http://127.0.0.1:9998',
      env: {
        ADMIN_SUPERUSER_EMAIL: "superuser@example.com",
        ADMIN_SUPERUSER_PASSWORD: "password"
      }
    },
});
