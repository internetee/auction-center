/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application
// logic in a relevant structure within app/javascript and only use these pack
// files to reference that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the
// appropriate layout file, like app/views/layouts/application.html.erb

// Default Rails javascript and turbolinks
import Rails from 'rails-ujs';
require("chartkick").use(require("highcharts"))
import Turbolinks from 'turbolinks';
Rails.start();
Turbolinks.start();
import 'channels';
import 'jquery';

// UI modules
import '../src/semantic-ui/definitions/modules/transition.js';
import '../src/semantic-ui/definitions/modules/checkbox.js';
import '../src/semantic-ui/definitions/modules/dropdown.js';
import '../src/semantic-ui/definitions/modules/sidebar.js';
import '../src/semantic-ui/definitions/modules/popup.js';
import '../src/semantic-ui/semantic.less';

// Fonts
import 'typeface-raleway';

$(document).on('turbolinks:load', function() {
    $('.ui.dropdown').dropdown();

    $('.btn-menu').on('click', function(e) {
        $('.ui.sidebar')
            .sidebar('toggle');
    });

    $(window).scroll(function() {
        if (window.matchMedia('(max-width: 1024px)').matches
            && $(document).scrollTop() > 0) {
            $('.main-header').addClass('u-fixed');
        } else {
            $('.main-header').removeClass('u-fixed');
        }
    });
});
