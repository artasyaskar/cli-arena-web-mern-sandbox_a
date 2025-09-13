import fs from 'fs';
import path from 'path';

describe('Backend Layered Architecture', () => {
  const serverSrcPath = path.join(__dirname, '..', '..', '..', 'src', 'server', 'src');

  it('should have a services directory with auth and product services', () => {
    const authServicePath = path.join(serverSrcPath, 'services', 'authService.ts');
    const productServicePath = path.join(serverSrcPath, 'services', 'productService.ts');

    expect(fs.existsSync(authServicePath)).toBe(true);
    expect(fs.existsSync(productServicePath)).toBe(true);
  });

  it('should have a repositories directory with a product repository', () => {
    const productRepoPath = path.join(serverSrcPath, 'repositories', 'productRepository.ts');

    expect(fs.existsSync(productRepoPath)).toBe(true);
  });

  it('should have significantly smaller controller files', () => {
    // This is a proxy metric for checking if logic was moved.
    // We check if the file size is below a certain threshold.
    const authControllerPath = path.join(serverSrcPath, 'controllers', 'authController.ts');
    const productControllerPath = path.join(serverSrcPath, 'controllers', 'productController.ts');

    const authControllerStats = fs.statSync(authControllerPath);
    const productControllerStats = fs.statSync(productControllerPath);

    // The refactored controller should be very lean. We expect it to be less than 2KB.
    // The original, fatter controller would be larger than this.
    expect(authControllerStats.size).toBeLessThan(2000);
    expect(productControllerStats.size).toBeLessThan(1500);
  });
});
