const fs = require('fs');
const path = require('path');
const csv = require('csv-parser');
const mongoose = require('mongoose');
require('dotenv').config();

// MongoDB Connection with TLS
async function connectToMongoDB() {
  const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/hospital_finder';
  
  const mongoOptions = {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  };

  // Add TLS options if SSL connection string is detected
  if (mongoUri.includes('mongodb+srv://') || mongoUri.includes('ssl=true')) {
    mongoOptions.ssl = true;
    mongoOptions.retryWrites = true;
    mongoOptions.w = 'majority';
    
    // Optional: For self-signed certificates
    // mongoOptions.tlsCAFile = process.env.TLS_CA_FILE;
    // mongoOptions.tlsCertificateKeyFile = process.env.TLS_CERT_FILE;
  }

  try {
    await mongoose.connect(mongoUri, mongoOptions);
    console.log('✓ MongoDB Connected Successfully with TLS');
    return true;
  } catch (error) {
    console.error('✗ MongoDB Connection Error:', error.message);
    return false;
  }
}

// Hospital Schema
const hospitalSchema = new mongoose.Schema({
  srNo: String,
  name: { type: String, required: true, index: true },
  category: { type: String, index: true },
  discipline: String,
  address: String,
  state: { type: String, index: true },
  district: { type: String, index: true },
  pincode: String,
  telephone: String,
  emergencyNum: String,
  bloodbankPhone: String,
  email: String,
  website: String,
  specialties: [String],
  facilities: [String],
  accreditation: String,
  ayush: String,
  totalBeds: Number,
  availableBeds: { type: Number, index: true },
  privateWards: Number,
  location: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point',
    },
    coordinates: [Number], // [longitude, latitude]
  },
  createdAt: { type: Date, default: Date.now },
}, { collection: 'hospitals' });

// Create geospatial index
hospitalSchema.index({ 'location': '2dsphere' });

const Hospital = mongoose.model('Hospital', hospitalSchema);

// Parse CSV and load to MongoDB
async function loadHospitalsFromCSV() {
  const csvFilePath = path.join(__dirname, '../data/hospitals.csv');
  const hospitals = [];
  let recordCount = 0;
  let errorCount = 0;

  return new Promise((resolve, reject) => {
    fs.createReadStream(csvFilePath)
      .pipe(csv())
      .on('data', (row) => {
        try {
          // Parse coordinates
          let coordinates = null;
          if (row.Location_Coordinates && row.Location_Coordinates.trim()) {
            const coords = row.Location_Coordinates.split(',').map(c => parseFloat(c.trim()));
            if (coords.length === 2 && !isNaN(coords[0]) && !isNaN(coords[1])) {
              // GeoJSON format: [longitude, latitude]
              coordinates = [coords[1], coords[0]];
            }
          }

          // Parse array fields
          const specialties = row.Specialties 
            ? row.Specialties.split(',').map(s => s.trim()).filter(s => s)
            : [];
          
          const facilities = row.Facilities
            ? row.Facilities.split(',').map(f => f.trim()).filter(f => f)
            : [];

          const hospital = {
            srNo: row.Sr_No || '',
            name: row.Hospital_Name || '',
            category: row.Hospital_Category || '',
            discipline: row.Discipline_Systems_of_Medicine || '',
            address: row.Address_Original_First_Line || '',
            state: row.State || '',
            district: row.District || '',
            pincode: row.Pincode || '',
            telephone: row.Telephone || '',
            emergencyNum: row.Emergency_Num || '',
            bloodbankPhone: row.Bloodbank_Phone_No || '',
            email: row.Hospital_Primary_Email_Id || '',
            website: row.Website || '',
            specialties,
            facilities,
            accreditation: row.Accreditation || '',
            ayush: row.Ayush || '',
            totalBeds: parseInt(row.Total_Num_Beds) || 0,
            availableBeds: parseInt(row.Available_Beds) || 0,
            privateWards: parseInt(row.Number_Private_Wards) || 0,
            location: coordinates ? {
              type: 'Point',
              coordinates,
            } : undefined,
          };

          // Filter out undefined location
          if (!hospital.location) {
            delete hospital.location;
          }

          hospitals.push(hospital);
          recordCount++;
        } catch (error) {
          errorCount++;
          console.error(`Error parsing row ${recordCount + 1}:`, error.message);
        }
      })
      .on('end', async () => {
        console.log(`\n✓ CSV parsed: ${recordCount} records read, ${errorCount} errors`);

        if (hospitals.length === 0) {
          console.log('✗ No hospitals to insert');
          reject(new Error('No hospitals parsed from CSV'));
          return;
        }

        try {
          // Clear existing data (optional)
          // await Hospital.deleteMany({});
          // console.log('✓ Cleared existing hospital data');

          // Insert hospitals in batches to avoid memory issues
          const batchSize = 1000;
          let insertedCount = 0;

          for (let i = 0; i < hospitals.length; i += batchSize) {
            const batch = hospitals.slice(i, i + batchSize);
            const result = await Hospital.insertMany(batch, { ordered: false }).catch(err => {
              // Continue on duplicate key errors
              if (err.code === 11000) {
                console.log(`  ⚠ Some duplicates skipped in batch ${Math.floor(i / batchSize) + 1}`);
                return { insertedCount: batch.length - err.writeErrors?.length || 0 };
              }
              throw err;
            });
            
            insertedCount += result?.insertedCount || batch.length;
            console.log(`  ✓ Batch ${Math.floor(i / batchSize) + 1}: ${result?.insertedCount || batch.length} hospitals inserted`);
          }

          console.log(`\n✓ Successfully loaded ${insertedCount} hospitals into MongoDB`);

          // Get collection stats
          const stats = await Hospital.collection.stats();
          console.log(`\n📊 Collection Statistics:`);
          console.log(`   Total documents: ${stats.count}`);
          console.log(`   Avg document size: ${(stats.avgObjSize / 1024).toFixed(2)} KB`);

          resolve({ success: true, insertedCount, totalRecords: recordCount });
        } catch (error) {
          console.error('✗ Error inserting hospitals:', error.message);
          reject(error);
        }
      })
      .on('error', (error) => {
        console.error('✗ Error reading CSV:', error.message);
        reject(error);
      });
  });
}

// Main execution
async function main() {
  console.log('🏥 Hospital CSV to MongoDB Loader');
  console.log('═══════════════════════════════════\n');

  try {
    // Connect to MongoDB
    const connected = await connectToMongoDB();
    if (!connected) {
      process.exit(1);
    }

    // Load hospitals from CSV
    const result = await loadHospitalsFromCSV();

    console.log('\n✓ Data loading completed successfully!');
    console.log(`✓ Result:`, result);

  } catch (error) {
    console.error('\n✗ Error during data loading:', error.message);
    process.exit(1);
  } finally {
    // Close MongoDB connection
    await mongoose.connection.close();
    console.log('\n✓ MongoDB connection closed');
  }
}

// Run the script
main();
