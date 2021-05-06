# CodacyMetrics

Pull and process your organization metrics / stats from Codacy API

## Requirements to run

### Elixir setup
Make sure you have an Elixir setup[1] then install project dependencies with `mix deps.get`

[1] https://elixir-lang.org/install.html

### Configure the codacy api token
  change thesse lines in the `secrets.ex` file:  
  `@api_token "YOUR TOKEN"`  
  `@organization "YOUR ORG"`

## Run

### All metrics
`mix all_metrics`

### Tech Debt 
`mix metrics techDebt`

### Issues Count 
`mix metrics numberIssues`
