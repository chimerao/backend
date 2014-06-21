/* jshint indent: 2, undef: true, unused: strict, strict: true, eqeqeq: true, trailing: true, curly: true, latedef: true, quotmark: single, maxlen: 132, mootools: true */
/* global IG: false */

IG.extend('profileSubmissions', function () {
  'use strict';

  var sendSubmission = function (file) {
    var thumbnailsDiv = $('thumbnails'),
      thumbnail = new Element('div'),
      image = new Element('img'),
      link = new Element('a', { 'class' : 'thumbnail' }),
      progress = new Element('img', { src: '/assets/progress_bar.gif', 'class' : 'progress' }),
      deleteButton = new Element('div', { 'class' : 'delete',  html: 'X' }),
      submissions_url = '/profiles/' + IG.currentProfile.id + '/submissions';

    image.inject(link);
    link.inject(thumbnail);
    progress.inject(thumbnail);

    IG.JSON.sendFile(submissions_url, file, {
      onLoadStart: function () {
        thumbnail.inject(thumbnailsDiv, 'top');
        $('submission_file').value = null;
      },
      onProgress: function (e) {
        var loaded = e.loaded,
          total = e.total;
        progress.setStyle('width', parseInt(loaded / total * 100, 10).limit(0, 100) + '%');
      },
      onLoadEnd: function () {
        progress.setStyle('width', '100%');
      },
      onSuccess: function (submission) {
        var profile_submission_url = '/profiles/' + IG.currentProfile.id + '/submissions/' + submission.id;
        image.setProperties({
          id: 'thumbnail-' + submission.id,
          src: submission.image.thumb_240.url
        });
        link.setProperties({
          href: profile_submission_url + '/edit'
        });
        deleteButton.inject(thumbnail);
        deleteButton.addEvent('click', function () {
          IG.JSON.delete(profile_submission_url, {
            onSuccess: function () {
              thumbnail.fadeAndDestroy();
            }
          });
        });
        progress.destroy();
      }
    });
  };

  return {
    new: {
      init: function () {
        IG.submissionEdit.init();
      }
    },

    unpublished: {
      init: function () {
        var dropZone = $(document.window),
          fileInput = $('submission_file');

        dropZone.addEvents({
          dragover: function (e) {
            e.preventDefault();
          },
          drop: function (e) {
            e.preventDefault();
            var dataTransfer = e.event.dataTransfer;
            if (dataTransfer) {
              Array.each(dataTransfer.files, sendSubmission);
            }
          }
        });

        fileInput.addEvent('change', function () {
          var files = [];
          // Simple cloning so I can erase the file input ASAP.
          Array.each(fileInput.files, function (file) {
            files.push(file);
          });
          Array.each(files, sendSubmission);
        });

        $('thumbnails').getChildren('div').each(function (thumbnail) {
          var link = thumbnail.getChildren('div.delete')[0],
            id = link.id.split('-')[1],
            url = '/profiles/' + IG.currentProfile.id + '/submissions/' + id;
          link.addEvent('click', function () {
            IG.JSON.delete(url, {
              onSuccess: function () {
                thumbnail.fadeAndDestroy();
              }
            });
          });
        });
      }
    },

    edit: {
      init: function () {
        IG.submissionEdit.init();
      }
    },

    series: {
      init: function () {
        IG.submissionEdit.init();
      }
    }
  };
});
