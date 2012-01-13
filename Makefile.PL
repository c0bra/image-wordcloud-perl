use inc::Module::Install;

name     'HTML-WordCloud';
all_from 'lib/HTML/WordCloud.pm';
author   q{Brian Hann <brian.hann@gmail.com>};
license  'perl';

build_requires 'Test::More';

requires 'Data::Types' => '0.09';
requires 'Search::Dict';

auto_install;

WriteAll;

