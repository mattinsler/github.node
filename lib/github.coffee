fs = require 'fs'
Rest = require 'rest.node'

Api = {
  User: class UserApi
    constructor: (@client) ->
    get: (cb) -> @client.get('/user', cb)
  
  Repos: class ReposApi
    constructor: (@client) ->
    list: (opts, cb) -> @client.get('/user/repos', opts, cb)
    create: (data, cb) -> @client.post('/user/repos', data, cb)
  
  Repo: class RepoApi
    constructor: (@client, @repo) ->
      @contributors = new Api.Contributors(@client, @repo)
      @hooks = new Api.Hooks(@client, @repo)
    
    get: (cb) -> @client.get("/repos/#{@repo}", cb)
    update: (updates, cb) -> @client.put("/repos/#{@repo}", updates, cb)
    
    download_archive: (archive_format, output_file, cb) ->
      fs.exists output_file, (exists) =>
        return cb(new Error('output_file ' + output_file + ' already exists')) if exists
        try
          out = fs.createWriteStream(output_file)
        catch err
          return cb?(err)
        
        on_error = (err) ->
          out.destroy()
          fs.unlinkSync(output_file)
          cb?(err)
        
        opts = @client.create_request_opts('get', "/repos/#{@repo}/#{archive_format}", {}, followRedirect: false)
        out.once('error', on_error)
        out.once 'close', -> cb?(null, output_file)
        
        @client.get "/repos/#{@repo}/#{archive_format}", (err) =>
          return on_error(err) unless err.status_code is 302
          
          Rest.request.get(err.headers.location).pipe(out)
        , {followRedirect: false}
    
    hook: (id) -> new Api.Hook(@client, @repo, id)
  
  Contributors: class ContributorsApi
    constructor: (@client, @repo) ->
    list: (opts, cb) -> @client.get("/repos/#{@repo}/contributors", opts, cb)
  
  Hooks: class HooksApi
    constructor: (@client, @repo) ->
    list: (cb) -> @client.get("/repos/#{@repo}/hooks", cb)
    create: (data, cb) -> @client.post("/repos/#{@repo}/hooks", data, cb)
  
  Hook: class HookApi
    constructor: (@client, @repo, @id) ->
    get: (cb) -> @client.get("/repos/#{@repo}/hooks/#{@id}", cb)
    update: (updates, cb) -> @client.put("/repos/#{@repo}/hooks/#{@id}", updates, cb)
    remove: (cb) -> @client.delete("/repos/#{@repo}/hooks/#{@id}", cb)
    test: (cb) -> @client.post("/repos/#{@repo}/hooks/#{@id}/tests", cb)
  
  Authorizations: class AuthorizationsApi
    constructor: (@client) ->
    list: (cb) -> @client.get('/authorizations', cb)
    create: (data, cb) -> @client.post('/authorizations', data, cb)
}

class Github extends Rest
  @hooks:
    user_agent: (request_opts, opts) ->
      request_opts.headers ?= {}
      request_opts.headers['User-Agent'] = 'github.node'
    
    basic_auth: (user, pass) ->
      (request_opts, opts) ->
        request_opts.headers ?= {}
        request_opts.headers.Authorization = 'Basic ' + new Buffer("#{user}:#{pass}").toString('base64')
    
    access_token: (access_token) ->
      (request_opts, opts) ->
        request_opts.headers ?= {}
        request_opts.headers.Authorization = 'token ' + access_token
    
    get: (request_opts, opts) ->
      request_opts.qs = opts
    
    post: (request_opts, opts) ->
      request_opts.json = opts
  
  constructor: (@options = {}) ->
    super(base_url: 'https://api.github.com')
    
    @hook('pre:request', Github.hooks.user_agent)
    @hook('pre:request', Github.hooks.basic_auth(@options.username, @options.password)) if @options.username? and @options.password?
    @hook('pre:request', Github.hooks.access_token(@options.access_token)) if @options.access_token?
    @hook('pre:get', Github.hooks.get)
    @hook('pre:post', Github.hooks.post)
    
    @repos = new Api.Repos(@)
    @user = new Api.User(@)
    @authorizations = new Api.Authorizations(@)
  
  repo: (repo) -> new Api.Repo(@, repo)

module.exports = Github
