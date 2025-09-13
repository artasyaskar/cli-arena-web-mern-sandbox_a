import fs from 'fs';
import path from 'path';

describe('Frontend Component Refactoring', () => {
  const componentsDir = path.join(__dirname, '..', '..', '..', 'src', 'client', 'src', 'components');

  const expectedComponents = [
    'AuthForm.tsx',
    'ProductList.tsx',
    'AddProductForm.tsx',
    'SearchBar.tsx',
    'Notifications.tsx',
  ];

  it('should have a components directory', () => {
    expect(fs.existsSync(componentsDir)).toBe(true);
    expect(fs.lstatSync(componentsDir).isDirectory()).toBe(true);
  });

  it.each(expectedComponents)('should have the %s component file', (componentFile) => {
    const componentPath = path.join(componentsDir, componentFile);
    expect(fs.existsSync(componentPath)).toBe(true);
  });

  it('should have a leaner App.tsx file', () => {
    const appPath = path.join(componentsDir, '..', 'App.tsx');
    const appStats = fs.statSync(appPath);
    // The refactored App.tsx should be much smaller than the original "god component".
    // We expect it to be less than 3KB.
    expect(appStats.size).toBeLessThan(3000);
  });
});
