/* jshint indent: 2, undef: true, unused: strict, strict: true, eqeqeq: true, trailing: true, curly: true, latedef: true, quotmark: single, maxlen: 132, mootools: true */
/* global IG: false */

IG.extend('journals', function () {
  'use strict';

  return {
    show: {
      init: function () {
        IG.comments.init();
      }
    }
  };
});
