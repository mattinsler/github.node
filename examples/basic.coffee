Github = require '../lib/github'
# client = new Github(username: process.env.GITHUB_USERNAME, password: process.env.GITHUB_PASSWORD)
client = new Github(access_token: process.env.GITHUB_ACCESS_TOKEN)

print = (err, data) ->
  console.log 'PRINT'
  if err?
    console.error(err)
    console.error(err.stack)
    return
  console.log data

# client.authorizations.list(print)
# client.authorizations.create(
#   scopes: ['repo']
#   note: 'awesomebox.es'
#   note_url: 'http://awesomebox.es'
#   client_id: process.env.GITHUB_CLIENT_ID
#   client_secret: process.env.GITHUB_CLIENT_SECRET
# , print)

client.repos.list(print)

# client.repo('anchorman.v2').download_archive('zipball', '/tmp/anchorman.v2.zip', print)

# client.repo('test').download_archive 'zipball', '/tmp/test.zip', (err, filename) ->
#   require('child_process').exec "unzip #{filename}", (err, stdout, stderr) ->
#     return print(err) if err?
#     console.log stdout

# client.repo('test').get_archive_url 'zipball', (err, url) ->
#   return print(err) if err?
#   
#   out = fs.createWriteStream('/tmp/foobar.zip')
#   out.on 'end', ->
#     console.log 'done'
#   
#   # request.get(url).pipe(zlib.createUnzip()).pipe(out)
#   request.get(url: url, followRedirect: true).pipe(out)

# client.repo('test').hooks.list(print)
# client.repo('test').hook(663743).test(print)

# client.repo('test').hooks.create(
#   name: 'web'
#   config: {
#     url: 'http://code.mattinsler.com/hooks/github/mattinsler/test'
#     content_type: 'json'
#   }
#   events: ['push']
#   active: false
# , print)
