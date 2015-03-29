var fs = require('fs');
var gulp = require('gulp');
var shell = require('gulp-shell');


gulp.task('watch', ['deploy'], function(){
	gulp.watch(['src/**/*.hx'],['haxe']);
});

gulp.task('haxe', shell.task([
	'haxe build.hxml'
	]
	));


gulp.task('deploy', function(){
	fs.mkdir('bin');
	gulp.src('templates/**/*').pipe(gulp.dest('bin'));	
});

gulp.task('default', ['deploy','haxe']);
