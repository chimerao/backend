# Chimerao Backend

## Introduction

The backend is a 100% REST API, allowing for JSON queries from any varieties of front ends (web, mobile, etc.) It is designed to be accessed purely via the API, leaving rendering purely to front end code. A primary goal is to make the site navigable purely via the API using HTTP methods.

It is written in Rails, designed for a web server using Passenger (Nginx was used on the development box.) It was also written with test/behavior driven development in mind, using the default Rails testing suite.
