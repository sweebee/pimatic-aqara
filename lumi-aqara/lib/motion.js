'use strict';

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _get = function get(object, property, receiver) { if (object === null) object = Function.prototype; var desc = Object.getOwnPropertyDescriptor(object, property); if (desc === undefined) { var parent = Object.getPrototypeOf(object); if (parent === null) { return undefined; } else { return get(parent, property, receiver); } } else if ("value" in desc) { return desc.value; } else { var getter = desc.get; if (getter === undefined) { return undefined; } return getter.call(receiver); } };

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

var Subdevice = require('./subdevice');

var Motion = function (_Subdevice) {
  _inherits(Motion, _Subdevice);

  function Motion(opts) {
    _classCallCheck(this, Motion);

    var _this = _possibleConstructorReturn(this, (Motion.__proto__ || Object.getPrototypeOf(Motion)).call(this, { sid: opts.sid, type: 'motion' }));

    _this._motion = null;
    _this._lux = null;
    _this._seconds = null;
    return _this;
  }

  _createClass(Motion, [{
    key: '_handleState',
    value: function _handleState(state) {
      _get(Motion.prototype.__proto__ || Object.getPrototypeOf(Motion.prototype), '_handleState', this).call(this, state);

      // message with lux value comes separately and seems to arrive before motion messages
      if (state.lux) this._lux = state.lux;

      if ('status' in state || 'no_motion' in state) {
        // when motion is detected then json contains only 'status' field with this specific value
        this._motion = state.status === 'motion';
        // in case of inactivity, json contains only 'no_motion' field
        // with seconds from last motion as the value (reports '120', '180', '300', '600', '1200' and finally '1800')
        this._seconds = state.no_motion;

        if (this._motion) this.emit('motion');else if (state.no_motion) this.emit('noMotion');
      }
    }
  }, {
    key: 'hasMotion',
    value: function hasMotion() {
      return this._motion;
    }
  }, {
    key: 'getLux',
    value: function getLux() {
      return this._lux;
    }
  }, {
    key: 'getSecondsSinceMotion',
    value: function getSecondsSinceMotion() {
      return this._seconds;
    }
  }]);

  return Motion;
}(Subdevice);

module.exports = Motion;