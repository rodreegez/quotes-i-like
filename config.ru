require 'rubygems'
require 'sinatra'
require 'httparty'
require 'dm-core'
require 'dm-migrations'
require 'dm-timestamps'
require 'bundler'
require 'yaml'

require './quote'

Bundler.setup

run Sinatra::Application


