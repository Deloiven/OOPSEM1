class SearchesController < ApplicationController

    def index
      @list = List.all.select(:id, :name)
      @movie = Movie.new
    end
  
    def omdb
      @movie = Movie.new
      @list = List.all.select(:id, :name)
      conn = Faraday.new(:url => 'https://q.kpfilm.org')
  
      @resp = conn.get do |req|
        req.params['apikey'] = ENV['KPFILM_API_KEY']
        req.params['s'] = params[:movie]
      end
  
      body = JSON.parse(@resp.body)
      if @resp.success?
        @movies = body["Search"]
      else
        @error = "There was a timeout. Please try again."
      end
      render 'index'
    end
  end

  Rails.application.routes.draw do
    resources :lists, :movies
    get '/search', to: 'searches#index'
    post '/search', to: 'searches#omdb'
    root 'lists#index'
  end

  def add_api_movie_to_list
    conn = Faraday.new(:url => 'http://www.omdbapi.com')

    @resp = conn.get do |req|
      req.params['apikey'] = ENV['OMDB_API_KEY']
      req.params['i'] = params[:movie_id]
    end

    body = JSON.parse(@resp.body)
    movie_params = { title: body["Title"], genre: body["Genre"], year: body["Year"], poster: body["Poster"], plot: body["Plot"], director: body["Director"] }
    movie_params.merge(params[:movie])
    @movie = Movie.new(movie_params)
    if @movie.save
      redirect_to movie_path(@movie)
    else
      flash[:error] = "Unable to save movie. Try again."
      render 'search'
    end
  end