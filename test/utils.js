const printLogs = result => {
  result.logs.map(log => {
    console.log(JSON.stringify(log, null, 2))
  })
}

module.exports = {
  printLogs
}
