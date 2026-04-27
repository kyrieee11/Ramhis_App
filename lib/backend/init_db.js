const { MongoClient, ObjectId } = require('mongodb');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017';
const DB_NAME = process.env.DB_NAME || 'ramhis';
const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'admin@ramhis.org';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'admin123456';

const client = new MongoClient(MONGODB_URI);

async function resetCollection(db, name) {
  const exists = await db.listCollections({ name }).toArray();
  if (exists.length) {
    await db.collection(name).deleteMany({});
  }
}

async function main() {
  await client.connect();
  const db = client.db(DB_NAME);

  const users = db.collection('users');
  const doctorProfiles = db.collection('doctor_profiles');
  const volunteerProfiles = db.collection('volunteer_profiles');
  const content = db.collection('content');
  const events = db.collection('events');
  const eventRegistrations = db.collection('event_registrations');
  const chatThreads = db.collection('chat_threads');
  const chatMessages = db.collection('chat_messages');

 await Promise.all([
  users.createIndex({ email: 1 }, { unique: true }),
  doctorProfiles.createIndex({ user_id: 1 }, { unique: true }),
  volunteerProfiles.createIndex({ user_id: 1 }, { unique: true }),
  content.createIndex({ slug: 1 }, { unique: true }),
  eventRegistrations.createIndex({ event_id: 1, user_id: 1 }, { unique: true }),
  chatThreads.createIndex({ participant_ids: 1 }),
  chatMessages.createIndex({ thread_id: 1, created_at: 1 }),
]);

  await Promise.all([
    resetCollection(db, 'users'),
    resetCollection(db, 'doctor_profiles'),
    resetCollection(db, 'volunteer_profiles'),
    resetCollection(db, 'content'),
    resetCollection(db, 'events'),
    resetCollection(db, 'event_registrations'),
    resetCollection(db, 'chat_threads'),
    resetCollection(db, 'chat_messages'),
  ]);

  const adminPassword = await bcrypt.hash(ADMIN_PASSWORD, 10);
  const doctorPassword = await bcrypt.hash('doctor123456', 10);
  const volunteerPassword = await bcrypt.hash('volunteer123456', 10);

  const now = new Date();

  const userDocs = [
    {
      _id: new ObjectId(),
      full_name: 'System Admin',
      email: ADMIN_EMAIL.toLowerCase(),
      password_hash: adminPassword,
      role: 'admin',
      account_type: 'admin',
      contact_number: '09170000001',
      birthdate: '1990-01-01',
      accepted_terms: true,
      status: 'active',
      is_verified: true,
      created_at: now,
      updated_at: now,
    },
    {
      _id: new ObjectId(),
      full_name: 'Dr. Maria Santos',
      email: 'maria.santos@ramhis.org',
      password_hash: doctorPassword,
      role: 'user',
      account_type: 'doctor',
      contact_number: '09170000002',
      birthdate: '1988-05-10',
      accepted_terms: true,
      status: 'pending',
      is_verified: false,
      created_at: now,
      updated_at: now,
    },
    {
      _id: new ObjectId(),
      full_name: 'Dr. Paulo Reyes',
      email: 'paulo.reyes@ramhis.org',
      password_hash: doctorPassword,
      role: 'user',
      account_type: 'doctor',
      contact_number: '09170000003',
      birthdate: '1985-09-20',
      accepted_terms: true,
      status: 'active',
      is_verified: true,
      created_at: now,
      updated_at: now,
    },
    {
      _id: new ObjectId(),
      full_name: 'John Dela Cruz',
      email: 'john.delacruz@ramhis.org',
      password_hash: volunteerPassword,
      role: 'user',
      account_type: 'volunteer',
      contact_number: '09170000004',
      birthdate: '1998-02-14',
      accepted_terms: true,
      status: 'active',
      is_verified: true,
      created_at: now,
      updated_at: now,
    },
    {
      _id: new ObjectId(),
      full_name: 'Anna Cruz',
      email: 'anna.cruz@ramhis.org',
      password_hash: volunteerPassword,
      role: 'user',
      account_type: 'volunteer',
      contact_number: '09170000005',
      birthdate: '1999-08-03',
      accepted_terms: true,
      status: 'pending',
      is_verified: false,
      created_at: now,
      updated_at: now,
    },
  ];

  await users.insertMany(userDocs);

  await doctorProfiles.insertMany([
    {
      user_id: userDocs[1]._id,
      verification_status: 'Pending',
      prc_license_number: 'PRC-1234567',
      specialty: 'Pediatrics',
      hospital_clinic: 'Pasig Medical Center',
      credential_file_url: '',
      created_at: now,
      updated_at: now,
    },
    {
      user_id: userDocs[2]._id,
      verification_status: 'Approved',
      prc_license_number: 'PRC-7654321',
      specialty: 'General Medicine',
      hospital_clinic: 'Laguna Family Clinic',
      credential_file_url: '',
      created_at: now,
      updated_at: now,
    },
  ]);

  await volunteerProfiles.insertMany([
    {
      user_id: userDocs[3]._id,
      verification_status: 'Approved',
      organization: 'RAM Volunteer Corps',
      skills: 'Logistics',
      supporting_file_url: '',
      created_at: now,
      updated_at: now,
    },
    {
      user_id: userDocs[4]._id,
      verification_status: 'Approved',
      organization: 'Youth Care Network',
      skills: 'Registration',
      supporting_file_url: '',
      created_at: now,
      updated_at: now,
    },
  ]);

  await content.insertOne({
    _id: new ObjectId(),
    slug: 'homepage_content',
    title: 'Homepage Content',
    body: 'Seeded homepage content for RAMHIS.',
    sections: {
      top_conditions: [
        { percent: '30%', change: '+10%', title: 'Respiratory Infections', color: 'warning' },
        { percent: '24%', change: '+6%', title: 'Hypertension Cases', color: 'danger' },
        { percent: '18%', change: '+4%', title: 'Pediatrics', color: 'success' },
      ],
      medication_needs: [
        { name: 'Amoxicillin', amount: '1,200 doses', risk: 'High Risk' },
        { name: 'Paracetamol', amount: '900 doses', risk: 'Medium Risk' },
        { name: 'Losartan', amount: '700 doses', risk: 'High Risk' },
      ],
      key_drivers: [
        'Increased antibiotic use',
        'Seasonal respiratory cases',
        'Limited rural medicine stocks',
        'Rising blood pressure cases',
      ],
    },
    created_at: now,
    updated_at: now,
  });

  const eventDocs = [
    {
      _id: new ObjectId(),
      title: 'Pasig Medical Mission',
      description: 'General consultation, pediatrics, and medicine dispensing for underserved families.',
      location: 'Pasig City',
      date: '2026-04-08',
      time: '08:00 AM',
      meeting_place: 'Pasig City Hall Grounds',
      created_at: now,
      updated_at: now,
    },
    {
      _id: new ObjectId(),
      title: 'Bulacan Outreach',
      description: 'Community outreach mission with doctor and volunteer support teams.',
      location: 'Bulacan',
      date: '2026-04-12',
      time: '07:30 AM',
      meeting_place: 'Bulacan Municipal Gym',
      created_at: now,
      updated_at: now,
    },
    {
      _id: new ObjectId(),
      title: 'Laguna Pediatric Checkup',
      description: 'Focused pediatric screening and medicine support for children.',
      location: 'Laguna',
      date: '2026-04-18',
      time: '09:00 AM',
      meeting_place: 'Laguna Health Center',
      created_at: now,
      updated_at: now,
    },
  ];

  await events.insertMany(eventDocs);

  await eventRegistrations.insertMany([
    {
      _id: new ObjectId(),
      event_id: eventDocs[0]._id,
      user_id: userDocs[2]._id,
      created_at: now,
    },
    {
      _id: new ObjectId(),
      event_id: eventDocs[0]._id,
      user_id: userDocs[3]._id,
      created_at: now,
    },
    {
      _id: new ObjectId(),
      event_id: eventDocs[1]._id,
      user_id: userDocs[4]._id,
      created_at: now,
    },
  ]);

  const threadId = new ObjectId();
  await chatThreads.insertOne({
    _id: threadId,
    name: 'John Dela Cruz',
    participant_ids: [userDocs[0]._id.toString(), userDocs[3]._id.toString()],
    last_message: 'Thank you for confirming my event registration.',
    unread: 1,
    updated_at: now,
    created_at: now,
  });

  await chatMessages.insertMany([
    {
      _id: new ObjectId(),
      thread_id: threadId,
      sender_id: userDocs[3]._id.toString(),
      message: 'Hello admin, I just wanted to confirm my event registration.',
      created_at: now,
    },
    {
      _id: new ObjectId(),
      thread_id: threadId,
      sender_id: userDocs[0]._id.toString(),
      message: 'You are confirmed for the Pasig Medical Mission.',
      created_at: now,
    },
    {
      _id: new ObjectId(),
      thread_id: threadId,
      sender_id: userDocs[3]._id.toString(),
      message: 'Thank you for confirming my event registration.',
      created_at: now,
    },
  ]);

  console.log('Database seeded successfully.');
  console.log(`Admin login: ${ADMIN_EMAIL} / ${ADMIN_PASSWORD}`);
  console.log('Doctor login: maria.santos@ramhis.org / doctor123456');
  console.log('Volunteer login: john.delacruz@ramhis.org / volunteer123456');

  await client.close();
}

main().catch(async (error) => {
  console.error('Seed failed:', error);
  await client.close();
  process.exit(1);
});
