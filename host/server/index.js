'use strict';

module.exports = function (app) {
  app.use(function (request, response, next) {
    response.set('Server', 'runtime-spike');
    next();
  });
};
