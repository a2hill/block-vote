### Testing
1. Start DB
When you stop the container you lose the data
```
docker run --name postgres -e POSTGRES_DB=vapor_database \
  --rm \
  -d \
  -e POSTGRES_USER=vapor_username \
  -e POSTGRES_PASSWORD=vapor_password \
  -p 5432:5432 -d postgres \
  -c shared_buffers=500MB \
  -c fsync=off
```

2. Start mock rpc server (required node v10)
Optionally: `nvm use 10`
`cd mock-rpc && npm run mock-server`

3. Run tests
`cmd + u`
