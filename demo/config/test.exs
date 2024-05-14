import Config

config :logger, level: :warning
config :phoenix, :plug_init_mode, :runtime

config :demo, DemoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "C+Yn8zjDt2z+Sbl3NhLDra8U+J1QlqLoTSLx7w9BkToiWOnPk58H9nqTq+Y9OR3A",
  server: false
