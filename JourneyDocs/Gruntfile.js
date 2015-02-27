module.exports = function (grunt) {
    'use strict';

    grunt.loadNpmTasks('grunt-php');
    grunt.loadNpmTasks('grunt-contrib-less');
    grunt.loadNpmTasks('grunt-contrib-watch');

    grunt.initConfig({
        php: {
            dist: {
                options: {
                    keepalive: true,
                    open: true,
                    port: 8085
                }
            }
        },
        less: {
            development: {
                options: {
                    cleancss: true,
                    report: 'min'
                },
                files: {
                    "templates/default/themes/daux-dark/css/daux-dark.css": "less/daux-dark.less"
                }
            }
        },
        watch: {
            scripts: {
                files: ['less/**/*.less'],
                tasks: ['less'],
                options: {
                    nospawn: true
                },
            },
        },
    });

    //grunt.registerTask('default', ['less', 'watch']);
    grunt.registerTask('default', ['php','less','watch']);
};