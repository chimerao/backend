IG.extend('profiles', function () {
  'use strict';

  return {
    new: {
      init: function () {
        IG.profiles.nameToUrlName();
      }
    },

    create: {
      init: function () {
        IG.profiles.nameToUrlName();
      }
    },

    show: {
      init: function () {
        var container = $('profile-container');
        IG.widgets.latestSubmission.setContainer(container);
        IG.widgets.latestSubmission.render();
//        IG.widgets.recentSubmissions.setContainer(container);
//        IG.widgets.recentSubmissions.render();
        IG.widgets.latestJournal.setContainer(container);
        IG.widgets.latestJournal.render();
      }
    },

    nameToUrlName: function () {
      $('profile_name').addEvent('keyup', IG.profiles.populateUrlName);
    },

    populateUrlName: function () {
      var profileNameValue = $('profile_name').value;

      profileNameValue = profileNameValue.replace(/\s/g, '_');
      profileNameValue = profileNameValue.replace(/\W/g, '');

      $('profile_site_identifier').value = profileNameValue;
    }
  };
});

IG.ProfileWidget = function (name, options) {
  'use strict';

  this._name = name;
  this._dataSource = options.dataSource;
  this._title = options.title;
  this._construct = options.construct;
  this._x = options.x || 0;
  this._y = options.y || 0;
  this._width = options.width || '46%'; // padding is 2% on either side
  this._height = options.height || '500px';

  this._container = null;
};
IG.ProfileWidget.prototype = (function () {
  'use strict';

  return {
    getData: function (callback) {
      IG.JSON.get(this._dataSource, {
        onSuccess: function (data) {
          callback(data);
        }
      });
    },

    setCoordinates: function (x, y) {
      this._x = x;
      this._y = y;
    },

    setDimensions: function (width, height) {
      this._width = width;
      this._height = height;
    },

    setContainer: function (containerElem) {
      this._container = containerElem;
    },

    render: function () {
      this.getData(function (data) {
        var htmlString = this._construct(data),
          elem = new Element('div', {
            'id': this._name,
            'class': 'widget',
            styles: {
              left: this._x,
              top: this._y,
              width: this._width,
              height: this._height
            }
          });
        new Element('h2', { html : this._title }).inject(elem);
        new Element('div', { html : htmlString }).inject(elem);
        elem.inject(this._container);
      }.bind(this));
    }
  };
}());


// Janky, remove this.
if (IG.profile) {
IG.widgets = {
  latestSubmission: new IG.ProfileWidget('latest_submission', {
    dataSource: '/profiles/' + IG.profile.id + '/submissions',
    title: 'Latest Submission',
    x: '0',
    y: '0',
    construct: function (submissions) {
      'use strict';
      var submission = submissions[0];
      return '<a href="{link}"><img src="{source}" /></a>'.substitute({
        link: '/submissions/' + submission.id,
        source: submission.image.thumb_400.url
      });
    }
  }),

  latestJournal: new IG.ProfileWidget('latest_journal', {
    dataSource: '/profiles/' + IG.profile.id + '/journals',
    title: 'Latest Journal',
    x: '50%',
    y: '0',
    construct: function (journals) {
      'use strict';
      var journal = journals[0];
      return '<h3><a href="{link}">{title}</a></h3><div>{body}</div><a href="{link}">More</a>'.substitute({
        link: '/journals/' + journal.id,
        title: journal.title,
        body: marked(journal.body.truncate(400))
      });
    }
  }),

  recentSubmissions: new IG.ProfileWidget('recent_submissions', {
    dataSource: '/profiles/' + IG.profile.id + '/submissions',
    title: 'Recent Submissions',
    x: '0',
    y: '0',
    construct: function (submissions) {
      'use strict';
      var subs = submissions.slice(0,4),
        div = new Element('div'),
        thumbnails = new Element('div', { id: 'thumbnails' });

      subs.each(function (submission) {
        IG.templates.thumbnail(submission).inject(thumbnails);
      });

      thumbnails.inject(div);
      return div.innerHTML;
    }
  })
};
}
