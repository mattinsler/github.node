(function() {
  var Api, AuthorizationsApi, CollaboratorsApi, Github, HookApi, HooksApi, RepoApi, ReposApi, Rest, UserApi, fs,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  fs = require('fs');

  Rest = require('rest.node');

  Api = {
    User: UserApi = (function() {
      function UserApi(client, user) {
        this.client = client;
        this.user = user;
        this.repos = new Api.Repos(this.client, this.user);
      }

      UserApi.prototype.get = function(cb) {
        return this.client.get("/user/" + this.user, cb);
      };

      return UserApi;

    })(),
    Repos: ReposApi = (function() {
      function ReposApi(client, user) {
        this.client = client;
        this.user = user;
      }

      ReposApi.prototype.list = function(opts, cb) {
        return this.client.get("/user" + (this.user != null ? 's/' + this.user : '') + "/repos", opts, cb);
      };

      ReposApi.prototype.create = function(data, cb) {
        return this.client.post("/user" + (this.user != null ? 's/' + this.user : '') + "/repos", data, cb);
      };

      return ReposApi;

    })(),
    Repo: RepoApi = (function() {
      function RepoApi(client, repo) {
        this.client = client;
        this.repo = repo;
        this.collaborators = new Api.Collaborators(this.client, this.repo);
        this.hooks = new Api.Hooks(this.client, this.repo);
      }

      RepoApi.prototype.get = function(cb) {
        return this.client.get("/repos/" + this.repo, cb);
      };

      RepoApi.prototype.update = function(updates, cb) {
        return this.client.put("/repos/" + this.repo, updates, cb);
      };

      RepoApi.prototype.download_archive = function(archive_format, output_file, cb) {
        var _this = this;
        return fs.exists(output_file, function(exists) {
          var err, on_error, opts, out;
          if (exists) {
            return cb(new Error('output_file ' + output_file + ' already exists'));
          }
          try {
            out = fs.createWriteStream(output_file);
          } catch (_error) {
            err = _error;
            return typeof cb === "function" ? cb(err) : void 0;
          }
          on_error = function(err) {
            out.destroy();
            fs.unlinkSync(output_file);
            return typeof cb === "function" ? cb(err) : void 0;
          };
          opts = _this.client.create_request_opts('get', "/repos/" + _this.repo + "/" + archive_format, {}, {
            followRedirect: false
          });
          out.once('error', on_error);
          out.once('close', function() {
            return typeof cb === "function" ? cb(null, output_file) : void 0;
          });
          return _this.client.get("/repos/" + _this.repo + "/" + archive_format, function(err) {
            if (err.status_code !== 302) {
              return on_error(err);
            }
            return Rest.request.get(err.headers.location).pipe(out);
          }, {
            followRedirect: false
          });
        });
      };

      RepoApi.prototype.hook = function(id) {
        return new Api.Hook(this.client, this.repo, id);
      };

      return RepoApi;

    })(),
    Collaborators: CollaboratorsApi = (function() {
      function CollaboratorsApi(client, repo) {
        this.client = client;
        this.repo = repo;
      }

      CollaboratorsApi.prototype.list = function(opts, cb) {
        return this.client.get("/repos/" + this.repo + "/collaborators", opts, cb);
      };

      return CollaboratorsApi;

    })(),
    Hooks: HooksApi = (function() {
      function HooksApi(client, repo) {
        this.client = client;
        this.repo = repo;
      }

      HooksApi.prototype.list = function(cb) {
        return this.client.get("/repos/" + this.repo + "/hooks", cb);
      };

      HooksApi.prototype.create = function(data, cb) {
        return this.client.post("/repos/" + this.repo + "/hooks", data, cb);
      };

      return HooksApi;

    })(),
    Hook: HookApi = (function() {
      function HookApi(client, repo, id) {
        this.client = client;
        this.repo = repo;
        this.id = id;
      }

      HookApi.prototype.get = function(cb) {
        return this.client.get("/repos/" + this.repo + "/hooks/" + this.id, cb);
      };

      HookApi.prototype.update = function(updates, cb) {
        return this.client.put("/repos/" + this.repo + "/hooks/" + this.id, updates, cb);
      };

      HookApi.prototype.remove = function(cb) {
        return this.client["delete"]("/repos/" + this.repo + "/hooks/" + this.id, cb);
      };

      HookApi.prototype.test = function(cb) {
        return this.client.post("/repos/" + this.repo + "/hooks/" + this.id + "/tests", cb);
      };

      return HookApi;

    })(),
    Authorizations: AuthorizationsApi = (function() {
      function AuthorizationsApi(client) {
        this.client = client;
      }

      AuthorizationsApi.prototype.list = function(cb) {
        return this.client.get('/authorizations', cb);
      };

      AuthorizationsApi.prototype.create = function(data, cb) {
        return this.client.post('/authorizations', data, cb);
      };

      return AuthorizationsApi;

    })()
  };

  Github = (function(_super) {
    __extends(Github, _super);

    Github.hooks = {
      user_agent: function(request_opts, opts) {
        if (request_opts.headers == null) {
          request_opts.headers = {};
        }
        return request_opts.headers['User-Agent'] = 'github.node';
      },
      basic_auth: function(user, pass) {
        return function(request_opts, opts) {
          if (request_opts.headers == null) {
            request_opts.headers = {};
          }
          return request_opts.headers.Authorization = 'Basic ' + new Buffer("" + user + ":" + pass).toString('base64');
        };
      },
      access_token: function(access_token) {
        return function(request_opts, opts) {
          if (request_opts.headers == null) {
            request_opts.headers = {};
          }
          return request_opts.headers.Authorization = 'token ' + access_token;
        };
      },
      get: function(request_opts, opts) {
        return request_opts.qs = opts;
      },
      post: function(request_opts, opts) {
        return request_opts.json = opts;
      }
    };

    function Github(options) {
      this.options = options != null ? options : {};
      Github.__super__.constructor.call(this, {
        base_url: 'https://api.github.com'
      });
      this.hook('pre:request', Github.hooks.user_agent);
      if ((this.options.username != null) && (this.options.password != null)) {
        this.hook('pre:request', Github.hooks.basic_auth(this.options.username, this.options.password));
      }
      if (this.options.access_token != null) {
        this.hook('pre:request', Github.hooks.access_token(this.options.access_token));
      }
      this.hook('pre:get', Github.hooks.get);
      this.hook('pre:post', Github.hooks.post);
      this.repos = new Api.Repos(this);
      this.authorizations = new Api.Authorizations(this);
    }

    Github.prototype.user = function(user) {
      return new Api.User(this, user);
    };

    Github.prototype.repo = function(repo) {
      return new Api.Repo(this, repo);
    };

    return Github;

  })(Rest);

  module.exports = Github;

}).call(this);
