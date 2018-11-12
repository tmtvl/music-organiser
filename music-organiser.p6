#!/usr/bin/env perl6
use v6;

use Audio::Taglib::Simple;


# %artist
# %album
# %title
# %comment
# %genre
# %year
# %track
sub file-to-destination (Str $file, Str $dest-format, Int $file-count? --> Str) {
	my $extension = $file.IO.extension;
	my Str $dest = $dest-format;
	$dest ~= '.' ~ $extension if ?$extension;
	my $taglib = Audio::Taglib::Simple.new($file);
	my $fmt = '%0' ~ $file-count.codes ~ 'd' if ?$file-count;

	FORMAT: for <artist album title comment genre year track> -> $token {
		next FORMAT unless $dest-format ~~ /"%$token"/;

		my $subst;

		given $token {
			when $token eq 'artist'  { $subst = $taglib.artist;  }
			when $token eq 'album'   { $subst = $taglib.album;   }
			when $token eq 'title'   { $subst = $taglib.title;   }
			when $token eq 'comment' { $subst = $taglib.comment; }
			when $token eq 'genre'   { $subst = $taglib.genre;   }
			when $token eq 'year'    { $subst = $taglib.year;    }
			when $token eq 'track'   {
				if (?$file-count) {
					$subst = $taglib.track.fmt($fmt);
				}
				else {
					$subst = $taglib.track;
				}
			}
			default                  { $subst = $token;          }
		}

		$dest ~~ s:g/"%$token"/$subst/;
	}

	return $dest;
}

sub map-files-to-destinations (Str @files, Str $music-path, Str $dest-format) {
	my Str @destinations = @files.map({ $music-path.IO.child(file-to-destination($_, $dest-format, @files.elems)).Str });

	if (@destinations.unique.elems < @files.elems) {
		say $*ERR: "Cowardly refusing to squash files.";
		exit(1);
	}

	my %map;

	for @files.kv -> $i, $file {
		%map{$file} = @destinations[$i];
	}

	return %map;
}

sub MAIN (Str $download-path, Str :$music-path = %*ENV{'HOME'}.IO.child('Music').Str, Str :$dest-format = '%artist/%album/%track - %title') {
	say "Moving files from $download-path.";

	if (!$music-path.IO.d) {
		say "$music-path is not a valid directory.";
		exit(1);
	}

	my Str @files = $download-path.IO.dir.map({ .Str });

	for map-files-to-destinations(@files, $music-path, $dest-format).kv -> $a, $b {
		mkdir($b.IO.parent);
		say "$a -> $b" if $a.IO.move($b);
	}
}
