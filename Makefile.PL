use inc::Module::Install;

name     'Image-WordCloud';
all_from 'lib/Image/WordCloud.pm';
author   q{Brian Hann <brian.hann@gmail.com>};
license  'perl';

build_requires 'Test::More';

requires 'Data::Types' => '0.09';
requires 'Params::Validate';
requires 'List::Util';
requires 'Search::Dict';
requires 'GD';
requires 'GD::Text::Align';
requires 'Color::Scheme';
requires 'Math::PlanePath::TheodorusSpiral';

install_share;

auto_install;

WriteAll;

