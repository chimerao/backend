/* jshint indent: 2, undef: true, unused: strict, strict: true, eqeqeq: true, trailing: true, curly: true, latedef: true, quotmark: single, maxlen: 132, mootools: true */
/* global IG: false, confirm */

IG.extend('profilePics', function () {
  'use strict';

  return {
    index: {
      init: function () {
        $('profile-pic-list').getChildren('li').each(function (li) {
          var id = li.id.split('-')[2];

          li.addEvent('click', function () {
            IG.JSON.patch('/profiles/' + IG.currentProfile.id + '/pics/' + id + '/make_default', {
              onSuccess: function () {
                window.location = window.location;
              }
            });
          });
        });

        $$('a.delete').each(function (link) {
          link.addEvent('click', function (e) {
            e.preventDefault();
            e.stopPropagation();
            if (confirm('Are you sure you want to delete this pic?')) {
              IG.JSON.delete(link.href, {
                onSuccess: function () {
                  var id = link.getParent().id.split('-')[2];
                  $('profile-pic-' + id).fadeAndDestroy();
                }
              });
            }
            return false;
          });
        });
      }
    }
  };
});