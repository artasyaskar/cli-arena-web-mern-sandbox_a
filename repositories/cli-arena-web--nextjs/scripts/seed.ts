const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding database...');

  await prisma.post.deleteMany();

  const posts = await Promise.all([
    prisma.post.create({
      data: {
        title: 'First Post',
        content: 'This is the content of the first post.',
        published: true,
      },
    }),
    prisma.post.create({
      data: {
        title: 'Second Post',
        content: 'This is the content of the second post.',
        published: false,
      },
    }),
    prisma.post.create({
      data: {
        title: 'Third Post',
        content: 'This is the content of the third post.',
        published: true,
      },
    }),
  ]);

  console.log('✅ Database seeded successfully!');
  console.log('Created posts:', posts.length);
}

main()
  .catch((e) => {
    console.error('❌ Error seeding database:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
