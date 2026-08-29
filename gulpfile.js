var gulp        = require('gulp'),
	plumber     = require('gulp-plumber'),
	browserSync = require('browser-sync'),
	stylus      = require('gulp-stylus'),
	uglify      = require('gulp-uglify'),
	concat      = require('gulp-concat'),
	jeet        = require('jeet'),
	rupture     = require('rupture'),
	koutoSwiss  = require('kouto-swiss'),
	prefixer    = require('autoprefixer-stylus'),
	cp          = require('child_process');

var messages = {
	jekyllBuild: '<span style="color: grey">Running:</span> $ jekyll build'
};

var jekyllCommand = (/^win/.test(process.platform)) ? 'jekyll.bat' : 'jekyll';

/**
 * Build the Jekyll Site
 */
function jekyllBuild(done) {
	browserSync.notify(messages.jekyllBuild);
	return cp.spawn(jekyllCommand, ['build'], {stdio: 'inherit'})
		.on('close', done);
}

/**
 * Reload the browser after a rebuild
 */
function reload(done) {
	browserSync.reload();
	done();
}

/**
 * Stylus task
 */
function styles() {
	return gulp.src('src/styl/main.styl')
		.pipe(plumber())
		.pipe(stylus({
			use: [koutoSwiss(), prefixer(), jeet(), rupture()],
			compress: true
		}))
		.pipe(gulp.dest('_site/assets/css/'))
		.pipe(browserSync.reload({stream: true}))
		.pipe(gulp.dest('assets/css'));
}

/**
 * Javascript Task
 */
function scripts() {
	return gulp.src('src/js/**/*.js')
		.pipe(plumber())
		.pipe(concat('main.js'))
		.pipe(uglify())
		.pipe(gulp.dest('assets/js/'))
		.pipe(browserSync.reload({stream: true}))
		.pipe(gulp.dest('_site/assets/js/'));
}

/**
 * Wait for jekyll-build, then launch the Server
 */
function serve(done) {
	browserSync({
		server: {
			baseDir: '_site'
		}
	});
	done();
}

/**
 * Watch stylus files for changes & recompile
 * Watch html/md files, run jekyll & reload BrowserSync
 */
function watch() {
	gulp.watch('src/styl/**/*.styl', styles);
	gulp.watch('src/js/**/*.js', scripts);
	gulp.watch(['*.html', '_includes/*.html', '_layouts/*.html', '_posts/*'],
		gulp.series(jekyllBuild, reload));
}

gulp.task('jekyll-build', jekyllBuild);
gulp.task('stylus', styles);
gulp.task('js', scripts);
gulp.task('watch', watch);
gulp.task('serve', gulp.series(jekyllBuild, serve));

/**
 * Default task: compile assets, build the Jekyll site,
 * launch BrowserSync and watch for changes.
 */
gulp.task('default', gulp.series(
	gulp.parallel(scripts, styles),
	jekyllBuild,
	serve,
	watch
));
