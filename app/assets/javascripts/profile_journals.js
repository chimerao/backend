/* jshint indent: 2, undef: true, unused: strict, strict: true, eqeqeq: true, trailing: true, curly: true, latedef: true, quotmark: single, maxlen: 132, mootools: true */
/* global IG: false, MediumEditor, HtmlToMarkdown */

IG.extend('profileJournals', function () {
  'use strict';

  return {
    setupForm: function (journalForm) {
      var titleEditable = $('title_editable'),
        bodyEditable = $('body_editable'),
        saveButton = $('page-control-save'),
        publishButton = $('page-control-publish'),
        filterButton = $('filter-control'),
        filterList = $('filter-list'),
        saveIntervalTime = 60 * 1000 * 1, // every 1 minute
        isSaved = false,
        saved = function () {
          saveButton.setProperty('html', 'Saved');
          isSaved = true;
        },
        notSaved = function () {
          if (isSaved) {
            saveButton.setProperty('html', 'Save');
            isSaved = false;
          }
        },
        saveJournal = function (e) {
          var clicked = false;

          if (e !== undefined) {
            e.stopPropagation();
            clicked = true;
          }
          if (clicked || !isSaved) { // don't make the call if we don't need to
            IG.JSON.postForm(journalForm, {
              onSuccess: function (journal) {
                if (journal !== null) { // This means it was just created
                  IG.journal = journal;
                  // We must change the form action so it doesn't create another one.
                  journalForm.action = journalForm.action + '/' + IG.journal.id;
                  // And add the hidden 'patch' method value for rails
                  new Element('input', {
                    name : '_method',
                    type : 'hidden',
                    value : 'patch'
                  }).inject(journalForm);
                }
                if (IG.journal.is_published === true && clicked) {
                  window.location.href = '/journals/' + IG.journal.id;
                } else {
                  saved();
                }
              }
            });
          }
          return false;
        };

      // Body
      new MediumEditor('.editable', {
        buttons: ['bold', 'italic', 'underline', 'strikethrough', 'anchor'],
        buttonLabels: {
          'anchor' : 'link'
        },
        placeholder: 'Start typing your entry'
      });

      // Title
      titleEditable.addEvent('input', function () {
        var content = titleEditable.get('html');

        content = content.replace(/<[^>]*>/, '');

        if (content === '') {
          titleEditable.addClass('placeholder');
          titleEditable.set('html', '');
        } else {
          titleEditable.removeClass('placeholder');
        }
        $('journal_title').value = content;
      });
      titleEditable.addEvent('keypress', function (e) {
        return e.code !== 13;
      });

      bodyEditable.addEvent('input', function () {
        $('journal_body').value = HtmlToMarkdown.parse(bodyEditable.get('html'));
      });

      filterButton.addEvent('click', function () {
        filterList.toggle();
      });

      saveButton.addEvent('click', saveJournal);
      window.setInterval(saveJournal, saveIntervalTime);

      if (publishButton !== null) {
        publishButton.addEvent('click', function (e) {
          e.stopPropagation();
          IG.JSON.postForm(journalForm, {
            onSuccess: function () {
              IG.JSON.patch(journalForm.action + '/publish', {
                onSuccess: function () {
                  window.location.href = '/journals/' + IG.journal.id;
                }
              });
            }
          });
          return false;
        });
      }

      document.addEventListener('keyup', notSaved);
    },

    new: {
      init: function () {
        IG.profileJournals.setupForm($('new_journal'));
      }
    },

    edit: {
      init: function () {
        IG.profileJournals.setupForm($('edit_journal_' + IG.journal.id));
      }
    },

    series: {
      init: function () {
        IG.profileJournals.setupForm($('new_journal'));
      }
    }
  };
});
