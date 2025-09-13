module.exports = {
  testEnvironment: 'node',
  testMatch: [
    '**/*.test.ts',
    '**/*.spec.ts',
    '../../tasks/**/*.test.ts'
  ],
  transform: {
    '^.+\\.tsx?$': 'ts-jest'
  },
  moduleFileExtensions: ['ts', 'tsx', 'js', 'jsx', 'json', 'node'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1'
  },
  testPathIgnorePatterns: ['/node_modules/'],
  verbose: true
};
