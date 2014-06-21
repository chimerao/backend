/* jshint devel: true, indent: 2, undef: true, unused: strict, strict: false, eqeqeq: true, trailing: true, curly: true, latedef: true, quotmark: single, maxlen: 120, mootools: true */
/* global $, _ */

//= require_directory ./collections
//= require_directory ./models
//= require_directory ./views

var Chi = Chi || {};
Chi.Views = Chi.Views || {};

// Function that's run when the page first loads.
Chi.init = function (id) {
  if (Chi.currentProfile === undefined) {
    // Logged out stuff.
  } else {
    Chi.ProfileSelect.attach($('#profile-select'));
    new Chi.Menu($('#settings'), {
      data: [
        ['Edit Profile', '/profiles/' + Chi.currentProfile.id + '/edit'],
        ['Logout', '/logout']
      ]
    }).attach();

    if ($('#banner')[0]) {
      Chi.Helpers.Links.Follow.attach($('#follow-link'));
    }
  }

  if (Chi.Views[Chi.controller] !== undefined &&
    Chi.Views[Chi.controller][Chi.action] !== undefined) {
    Chi.Views[Chi.controller][Chi.action].init(id);
  }
};

Chi.reset = function () {
  $('#content').empty();
};

// Centralied JSON requests and error handling.
Chi.JSON = (function () {

  // A single method to handle API errors.
  var handleFailure = function (response, failureFunc) {
    if (response.status === 500) {
      console.log(response.statusText);
    }
    if (failureFunc !== undefined) {
      failureFunc();
    } else {
      if (response.status === 0) {
        alert('The server went away. :(');
      } else {
        alert(response.status + ': ' + response.statusText);
      }
    }
  };

  return {
    /*
      A centralized GET method for JSON requests, allowing much better
      control and error handling should things come to that.

      Options

      success: Callback used when the request succeeds.
      failure: (optional) Callback used if the request fails.
    */
    get: function (path, options) {
      $.ajax({
        url: path,
        type: 'GET',
        dataType: 'json',
        cache: false,
        success: function (responseJSON) {
          options.success(responseJSON);
        },
        error: function (response) {
          handleFailure(response, options.failure);
        }
      });
    },

    /*
      A centralized POST method for JSON requests.

      Options

      data: The data as a plain javascript object.
      method: (optional) The HTTP method to use, defaults to 'POST'.
      success: Callback used when the request succeeds.
      failure: (optional) Callback used if the request fails.
    */
    post: function (path, options) {
      options = options || {};
      var data = options.data === undefined ? '' : options.data,
        method = options.method === undefined ? 'POST' : options.method;

      $.ajax({
        url: path,
        type: method,
        dataType: 'json',
        contentType: 'application/json',
        data: JSON.stringify(data),
        processData: false,
        success: function (responseJSON) {
          if (options.success) {
            options.success(responseJSON);
          }
        },
        error: function (response) {
          handleFailure(response, options.failure);
        }
      });
    },

    /*
      A centralized PATCH method for JSON requests.

      Options

      data: The data as a regular javascript object.
      success: Callback used when the request succeeds.
      failure: (optional) Callback used if the request fails.
    */
    patch: function (path, options) {
      options = options || {};
      options.method = 'PATCH';
      Chi.JSON.post(path, options);
    },

    /*
      A centralized DELETE method for JSON requests.

      Options

      success: Callback used when the request succeeds.
      failure: (optional) Callback used if the request fails.
    */
    delete: function (path, options) {
      options = options || {};
      options.method = 'DELETE';
      Chi.JSON.post(path, options);
    },

    /*
      Sends a file to an endpoint.

      Options

      success: Callback used when the request succeeds.
      loadStart: (optional) Callback used when the file upload starts.
      lrogress: (optional) Callback used during progress triggers.
      loadEnd: (optional) Callback used when the file upload ends.
      failure: (optional) Callback used if the request fails.
    */
    sendFile: function (url, file, options) {
      var xhr = new XMLHttpRequest();

      xhr.open('POST', url, true);
      xhr.setRequestHeader('Content-Disposition', 'inline; filename="' + file.name + '"');
      xhr.setRequestHeader('Content-Type', 'application/octet-stream');
      xhr.setRequestHeader('Accept', 'application/json');

      xhr.onloadstart = options.loadStart;
      xhr.onload = function (e) {
        options.success(JSON.decode(e.target.responseText));
      };
      xhr.upload.onprogress = options.progress;
      xhr.upload.onloadend = options.loadEnd;
      xhr.onerror = function (e) {
        handleFailure(e.target, options.failure);
      };

      xhr.send(file);
    }
  };
}());

// Helper methods for conveniently manipulating data.
Chi.Helpers = function () {

  var TIMEBLOCKS = {
    second: 1,
    minute: 60,
    hour: 60 * 60,
    day: 60 * 60 * 24,
    week: 60 * 60 * 24 * 7,
    month: 60 * 60 * 24 * 30,
    year: 60 * 60 * 24 * 365
  };

  return {
    timeAgo: function (timeString, length) {
      length = length || 'month';

      var time = new Date(timeString),
        timeInSeconds = time / 1000,
        now = Date.now() / 1000,
        secondsAgo = now - timeInSeconds,
        timePeriods = ['year', 'month', 'week', 'day', 'hour', 'minute', 'second'],
        shortMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
        relativeTimes = [],
        distance = now - TIMEBLOCKS.week * 2,
        returnString = '',
        i = 0,
        j = 0,
        t = null,
        interval = null,
        val = null;

      if (timeInSeconds > distance) {
        for (i, j = timePeriods.length; i < j; i += 1) {
          t = timePeriods[i];
          interval = TIMEBLOCKS[t];
          val = null;

          if (secondsAgo >= interval) {
            val = parseInt((secondsAgo / interval), 0);
            secondsAgo -= val * interval;
            relativeTimes.push(val + ' ' + t + (val > 1 ? 's' : ''));
          }
          if (val) {
            if (timePeriods.indexOf(length) <= timePeriods.indexOf(t)) {
              break;
            }
          }
        }
        return relativeTimes.join(', ') + ' ago';
      } else {
        returnString = shortMonths[time.getMonth()] + ' ' + time.getDate();
        if (time < Date.parse(new Date().getFullYear())) {
          returnString += ', ' + time.getFullYear();
        }
        return returnString;
      }
    },

    displayTags: function (tagList) {
      var adjustedTags = tagList.map(function (tag) {
        var a = document.createElement('a');

        a.setAttribute('href', '#');
        a.innerHTML = '#' + tag;
        return a.outerHTML;
      });
      return adjustedTags.join(' ');
    }
  };
};

Chi.Helpers.Links = (function () {

  return {
    Follow: (function () {
      var methodLink = function (e) {
          e.preventDefault();
          var target = $(e.target),
            method = target.data('method'),
            url = target.attr('href');

          Chi.JSON[method](url);
          if (method === 'post') {
            target.html('-');
            target.data('method', 'delete');
          } else {
            target.html('+');
            target.data('method', 'post');
          }
        };

      return {
        attach: function (elem) {
          elem.on('click', methodLink);
        }
      };
    }())
  };
}());

/*
  Universal templates. Uses underscore.js templating.

  Useful for working between development and production.
  We can assign templates as values, and check against them
  to see if they need to be loaded from the server. Or,
  they can be precompiled during deployment for performance.
*/
Chi.Templates = {};
Chi.Template = function (name) {
  this.name = name;
  this.url = '/assets/templates/' + name + '.html.ujs';
};
Chi.Template.prototype = {
  // Synchronous request to get the template from the server
  // if necessary. We don't want to continue until we have it.
  read: function () {
    var name = this.name;
    $.ajax({
      url: this.url,
      type: 'GET',
      async: false,
      success: function (responseText) {
        Chi.Templates[name] = _.template(responseText);
      }
    });
  },

  // If we already have the template stored, return that.
  get: function () {
    if (Chi.Templates[this.name] === undefined) {
      this.read();
    }
    return Chi.Templates[this.name];
  },

  // Useful for Backbone, which wants the template object.
  // template: new Chi.Template('journal').base();
  base: function () {
    return this.get(this.name);
  },

  // Useful for when you just want the HTML output.
  // html = new Chi.Template('journal').render(journal);
  render: function (obj) {
    return this.get(this.name)(obj);
  }
};

// Simple menus.
Chi.Menu = function (elem, options) {
  this._elem = elem;
  this._data = options.data;
  this._menu = null;
};
Chi.Menu.prototype = {
  attach: function () {
    this._elem.on('click', this.clickMenu.bind(this));
  },

  checkClickOutsideBox: function (e) {
    var target = $(e.target),
      clickedInMenu = target.parents('div.menu').length > 0,
      clickedMenu = target[0] === this._menu[0];
    if (!clickedInMenu && !clickedMenu) {
      this.destroy();
    }
  },

  clickMenu: function (e) {
    e.stopPropagation();
    this.openMenu();
    this._elem.off('click');
  },

  openMenu: function () {
    var ul = $('<ul/>'),
      menuHeight = this._data.length * 1.5 + 0.8;

    this._menu = $('<div class="menu" style="height:' + menuHeight + 'em;"/>');
    this._data.forEach(function (item) {
      var line = $('<a/>'),
        li = $('<li/>');
      line.html(item[0]);
      line.attr('href', item[1]);
      li.append(line);
      ul.append(li);
    });

    this._menu.append(ul);
    this._elem.append(this._menu);

    $(document.body).on('click', this.checkClickOutsideBox.bind(this));
  },

  destroy: function () {
    this._menu.remove();
    $(document.body).off('click');
    this._elem.on('click', this.clickMenu.bind(this));
    return false;
  }
};

/*
  Simple handler for the header profile select.
*/
Chi.ProfileSelect = (function () {

  var toggleLink = null,
    profilesPath = '/profiles',
    attachSwitchLinkForProfile = function (profile) {
      $('#profile-select-' + profile.id).on('click', function () {
        var switch_profiles_path = '/profiles/' + profile.id + '/switch';
        Chi.JSON.post(switch_profiles_path, {
          success: function () {
            window.location = window.location.pathname;
          }
        });
      });
    },

    checkClickOutsideBox = function (e) {
      var target = $(e.target),
        clickedInMenu = target.parents('div#profile-select-box').length > 0;
      if (!clickedInMenu) {
        closeBox();
      }
    },

    closeBox = function () {
      $('#profile-select-box').remove();
      toggleLink.html('▼');
      toggleLink.off('click', closeBox);
      toggleLink.on('click', openBox);
      $(document.body).off('click', checkClickOutsideBox);
      return false;
    },

    openBox = function () {
      Chi.JSON.get(profilesPath, {
        success: function (profiles) {
          var box = new Chi.Template('profile_select').render({ 'profiles': profiles });
          $('#profile-select').after(box);
          $('#profile-select-add').on('click', function () {
            window.location = '/profiles/new';
            return false;
          });

          profiles.forEach(function (profile) {
            attachSwitchLinkForProfile(profile);
          });

          toggleLink.html('▲');
          toggleLink.off('click', openBox);
          toggleLink.on('click', closeBox);

          $(document.body).on('click', checkClickOutsideBox);
        }
      });
    };

  return {
    attach: function (elem) {
      toggleLink = elem;
      toggleLink.on('click', openBox);
    }
  };
}());

