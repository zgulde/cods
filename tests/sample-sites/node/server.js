const app = require('express')()

app.get('/', (req, res) => {
  res.send('Node Site is Working!')
})

app.listen(54321, () => console.log('App started on port 54321'))
