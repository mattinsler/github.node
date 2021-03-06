fs = require 'fs'
Rest = require 'rest.node'

Api = {
  User: class UserApi
    constructor: (@client, @user) ->
      @orgs = new Api.Orgs(@client, @user)
      @repos = new Api.Repos(@client, @user)
    get: (cb) -> @client.get("/user/#{@user}", cb)
  
  Branches: class BranchesApi
    constructor: (@client, @repo) ->
    list: (cb) -> @client.get("/repos/#{@repo}/branches", cb)
  
  Org: class OrgApi
    constructor: (@client, @org) ->
      @repos = new Api.OrgRepos(@client)
  
  OrgRepos: class OrgReposApi
    constructor: (@client, @org) ->
    list: (opts, cb) -> @client.get("/orgs/#{@org}/repos", opts, cb)
  
  Orgs: class OrgsApi
    constructor: (@client, @user) ->
    list: (opts, cb) -> @client.get("/user#{if @user? then 's/' + @user else ''}/orgs", opts, cb)
    create: (data, cb) -> @client.post("/user#{if @user? then 's/' + @user else ''}/orgs", data, cb)
  
  Repos: class ReposApi
    constructor: (@client, @user) ->
    list: (opts, cb) -> @client.get("/user#{if @user? then 's/' + @user else ''}/repos", opts, cb)
    create: (data, cb) -> @client.post("/user#{if @user? then 's/' + @user else ''}/repos", data, cb)
  
  Repo: class RepoApi
    constructor: (@client, @repo) ->
      @collaborators = new Api.Collaborators(@client, @repo)
      @hooks = new Api.Hooks(@client, @repo)
      @branches = new Api.Branches(@client, @repo)
    
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
  
  Collaborators: class CollaboratorsApi
    constructor: (@client, @repo) ->
    list: (opts, cb) -> @client.get("/repos/#{@repo}/collaborators", opts, cb)
  
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
    
    @orgs = new Api.Orgs(@)
    @repos = new Api.Repos(@)
    @authorizations = new Api.Authorizations(@)
  
  org: (org) -> new Api.Org(@, org)
  repo: (repo) -> new Api.Repo(@, repo)
  user: (user) -> new Api.User(@, user)

module.exports = Github
