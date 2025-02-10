# To generate a coverage report for your Flutter project, run:
```bash
flutter test --coverage
```

# Option 1: VSCode Extension
Install the "Coverage Gutters" extension for VSCode
Open your project files to see coverage indicators in the editor
# Option 2: HTML Report
Install the LCOV package:
Terminal window
## On macOS
`brew install lcov`

## On Ubuntu
`sudo apt-get install lcov`

Generate an HTML report:
Terminal window
```bash
genhtml coverage/lcov.info -o coverage
```

Open coverage/index.html in your browser


