 # Retail Application
This repository contains the source code for a retail application built with Ruby on Rails.

## Prerequisites
Ensure that you have the following tools installed on your system:

```
GitHub
Ruby 3.2.2
Rails 7.1.2
```
## Getting Started
Follow these steps to set up and run the project on your local machine.

### 1. Clone the Repository


>git clone https://github.com/MoonRock000/retail-application.git

### 2. Install the bundler

Install the bundler using following command:

>bundle install

### 2. Create and Setup the Database
Run the following commands to create and set up the database.
```
bundle exec rake db:create
bundle exec rake db:setup
```
### 3. Start the Rails Server
Initiate the Rails server using the following command.
```
bundle exec rails s
````
>Now, you can access the site at http://localhost:3000.

## Running Test Cases
To run the test cases, execute the following commands:


```
bundle exec rspec spec/requests/approval_queues_spec.rb
bundle exec rspec spec/requests/products_spec.rb
bundle exec rspec spec/models/approval_queue_spec.rb
bundle exec rspec spec/models/product_spec.rb
```
