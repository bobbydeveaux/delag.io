var gulp = require('gulp')
    static_site = require('gulp-static-site')
    fileinclude = require('gulp-file-include')
    rename = require('gulp-rename')
    sass   = require('gulp-ruby-sass') 
    notify = require("gulp-notify") 
    htmlclean = require("gulp-htmlclean") 
    bower  = require('gulp-bower');

var paths = {
    sources: ['resources/content/**','templates/**'],
    templates: './templates/',
    stylesheets: ['css/**'],
    bowerDir: 'bower_components' ,
    sassPath: 'resources/sass',
};

gulp.task('icons', function() { 
    return gulp.src(paths.bowerDir + '/fontawesome/fonts/**.*') 
        .pipe(gulp.dest('./web/dist/fonts')); 
});

gulp.task('bower', function() { 
    return bower()
         .pipe(gulp.dest(paths.bowerDir)) 
});

gulp.task('site', function () {
    return gulp.src('resources/content/**/*.md')
        .pipe(static_site())
        .pipe(gulp.dest('web/'))
});

gulp.task('fileinclude', function() {
    return gulp.src(paths.templates + '*.tpl.html')
        .pipe(fileinclude())
        .pipe(rename({
            extname: ""
        }))
        .pipe(rename({
            extname: ".html"
        }))
        .pipe(htmlclean({
            protect: /<\!--%fooTemplate\b.*?%-->/g,
            edit: function(html) { return html.replace(/\begg(s?)\b/ig, 'omelet$1'); }
        }))
        .pipe(gulp.dest('./web'))
        .pipe(notify({ mesage: 'Includes: included' }));
});

gulp.task('css', function () {
    return gulp.src(['resources/css/*.css', './bower_components/fontawesome/css/font-awesome.min.css'])
        .pipe(gulp.dest('./web/dist/css'));
});

gulp.task('js', function () {
    return gulp.src(['resources/js/*.js'])
        .pipe(gulp.dest('./web/dist/js'));
});

gulp.task('images', function () {
    return gulp.src(['resources/images/*'])
        .pipe(gulp.dest('./web/dist/images'));
});

gulp.task('sass', function() { 
    return gulp.src(paths.sassPath + '/style.scss')
         .pipe(sass({
             style: 'compressed',
             loadPath: [
                 './resources/sass',
                 paths.bowerDir + '/bootstrap-sass-official/assets/stylesheets',
                 paths.bowerDir + '/fontawesome/scss',
             ]
         }) 
            .on("error", notify.onError(function (error) {
                 return "Error: " + error.message;
             }))) 
         .pipe(gulp.dest('./web/dist/css')); 
});


gulp.task('default', ['bower', 'fileinclude', 'icons', 'css', 'sass', 'js', 'images']);

// Rerun the task when a file changes
 gulp.task('watch', function() {
    gulp.watch(paths.sources, ['site']);
    gulp.watch(paths.stylesheets, ['css']);
});
