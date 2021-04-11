# Simple Todo App with MongoDB, Express.js and Node.js
The ToDo app uses the following technologies and javascript libraries:
* MongoDB
* Express.js
* Node.js
* express-handlebars
* method-override
* connect-flash
* express-session
* mongoose
* bcryptjs
* passport
* docker & docker-compose

## What are the features?
You can register with your email address, and you can create ToDo items. You can list ToDos, edit and delete them. 

# How to use
First install the depdencies by running the following from the root directory:

```
npm install --prefix src/
```

To run this application locally you need to have an insatnce of MongoDB running. A docker-compose file has been provided in the root director that will run an insatnce of MongoDB in docker. TO start the MongoDB from the root direction run the following command:

```
docker-compose up -d
```

Then to start the application issue the following command from the root directory:
```
npm run start --prefix src/
```

The application can then be accessed through the browser of your choise on the following:

```
localhost:5000
```

## Testing

Basic testing has been included as part of this application. This includes unit testing (Models Only), Integration Testing & E2E Testing.

### Linting:
Basic Linting is performed across the code base. To run linting, execute the following commands from the root directory:

```
npm run test-lint --prefix src/
```

### Unit Testing
Unit Tetsing is performed on the models for each object stored in MongoDB, they will vdaliate the model and ensure that required data is entered. To execute unit testing execute the following commands from the root directory:

```
npm run test-unit --prefix src/
```

### Integration Testing
Integration testing is included to ensure the applicaiton can talk to the MongoDB Backend and create a user, redirect to the correct page, login as a user and register a new task. 

Note: MongoDB needs to be running locally for testing to work (This can be done by spinning up the mongodb docker container).

To perform integration testing execute the following commands from the root directory:

```
npm run test-integration --prefix src/
```

### E2E Tests
E2E Tests are included to ensure that the website operates as it should from the users perspective. E2E Tests are executed in docker containers. To run E2E Tests execute the following commands:

```
chmod +x scripts/e2e-ci.sh
./scripts/e2e-ci.sh
```
### stonks inc deployment issue
Stonks’ current deployment method relies heavily on Pete to manually build and deploy the code that the developers produce. This current method has seen some bugs get through to production  causing additional pressures on customer service and the development team to fix these issues. 

The proposed solution will still maintain the use of GitHub as a basis for source control. Circle CI will monitor changes in the GitHub repository for changes which will then trigger the pipeline to run. Using Docker as a means to spin up environments for the purpose of integration and end to end testing. Docker-Compose is used to per-define docker image environment variables.   

The following details the circle ci config file.

### Commnads
The commands tag allows us to run a serise of scripts by calling install_deps(defined below), which will be used repeatedly throughout the circle ci config file.

```
commands:
  install_deps:
    steps:
      - run:
          name: Install Deps
          command: |
            mkdir -p ./src/node_modules
            npm install --prefix ./src
```
### Jobs
The jobs part of the config file is used for defining jobs to be executed in the workflow part of the file.

The ci-build job runs the linting and unit tests and then outputs the result of the test to the test-output directory.

```
ci-build:
    docker:
      - image: circleci/node:lts
    environment:
      JEST_JUNIT_OUTPUT_DIR: /home/circleci/project/test-output
    steps:
      - checkout
      - install_deps
      - run: 
          name: run linting tests
          command: |
            mkdir -p test-output
            npm run test-lint --prefix /src
      - run:
          name: run unit tests
          command: |
            npm run test-unit --prefix /src
      - store_test_results:
          path: /home/circleci/project/test-output/
```

The sast job runs the static code analysis, at the end of the job a fail senario was implimented to break the build if any sercurity vulnerabilities are found during the test.

```
  sast:
    docker:
      - image: circleci/node:lts
    steps:
      - checkout
      - run: 
          name: Install NodeJsScan
          command: |
            sudo apt update
            sudo apt install python3-pip
            pip3 install nodejsscan
      - run:
          name: run NodeJsScan
          command: |
            nodejsscan -d ./ -o sast-output.json
      - store_artifacts:
          path: sast-output.json
      - run:
          name: Parse sast output
          command: |
            # exit with non-zero if there is any security issues
            exit $(cat sast-output.json | jq .total_count.sec)
```

The integration test job preforms the integration tests. The results of the test results are output to directory integration-test-output

```
integration-tests:
    docker:
      - image: circleci/node:lts
      - image: mongo:4.0
    environment:
      APP_PORT: 5000
      JEST_JUNIT_OUTPUT_DIR: /home/circleci/project/integration-test-output
    steps:
      - checkout
      - install_deps
      - run:
          name: run integration tests
          command: |
            npm run test-integration --prefix src/
            mkdir -p integration-test-output
      - store_test_results:
          path:  /home/circleci/project/integration-test-output
```
e2e-tests job runs the end to end tests and stores the test results in e2e-test-output directory

```
 e2e-tests:
    docker:
      - image: circleci/node:lts
    environment:
      JEST_JUNIT_OUTPUT_DIR: /home/circleci/project/e2e-test-output
    steps:
      - checkout
      - setup_remote_docker:
          version: 19.03.12
      - install_deps
      - run:
          name: run e2e tests
          command: |
            chmod +x scripts/e2e-ci.sh
            ./scripts/e2e-ci.sh
            mkdir -p e2e-test-output
            pwd
      - store_test_results:
          path: /home/circleci/project/e2e-test-output

```
The pack job is the final job, it build the application and then stores it as a deployable artifact.

```
pack:
    docker:
      - image: circleci/node:lts
    environment:
      NODE_ENV: production
    steps:
      - checkout
      - install_deps
      - store_artifacts:
          path: ./
```
### Workflow

The workflow section of the config file determines the order the jobs are executed. The pack job is configured so it will only execute on the master branch.

```
workflows:
  build-and-packge:
    jobs:
      - ci-build
      - sast:
          requires:
            - ci-build
      - integration-tests:
          requires:
            - ci-build
            - sast
      - e2e-tests:
          requires:
            - ci-build
            - sast
            - integration-tests
      - pack: 
          requires:
            - ci-build
            - sast
          filters:
            branches:
              only:
                - master

```
###### This project is licensed under the MIT Open Source License
