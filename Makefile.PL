use inc::Module::Install;

name 'DenshiJisho';
all_from 'lib/DenshiJisho.pm';

requires 'Catalyst::Runtime' => '5.7011';
requires 'Catalyst::Engine::HTTP::Restarter';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Plugin::Log::Colorful';
requires 'Catalyst::TraitFor::Model::DBIC::Schema::QueryLog';
requires 'Catalyst::Plugin::I18N';
requires 'YAML'; # This should reflect the config file format you've chosen
                 # See Catalyst::Plugin::ConfigLoader for supported formats

requires 'Catalyst::View::TT' => 0;
requires 'Catalyst::View::JSON' => 0;
requires 'DBIx::Class' => 0.08010;

requires 'Lingua::EN::Numbers' => 0;
requires 'Text::MeCab' => 0;
requires 'Text::Balanced' => 0;
requires 'Catalyst::Model::DBIC::Schema' => 0;
requires 'HTTP::MobileAgent' => 0;
requires 'Catalyst::Plugin::FillInForm' => 0;
requires 'DBIx::Class::QueryLog' => 0;
requires 'DBIx::Class::QueryLog::Analyzer' => 0;
requires 'List::Compare' => 0;
requires 'Array::Unique' => 0;
requires 'Unicode::Japanese' => 0;
requires 'Data::Page::Balanced' => 0;
requires 'Lingua::JA::Romanize::Kana' => 0;
requires 'Locale::Maketext' => 0;

catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
