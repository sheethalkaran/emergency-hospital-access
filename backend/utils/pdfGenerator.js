const PDFDocument = require('pdfkit');
const fs = require('fs');
const path = require('path');

// Create temp directory if not exists
const tempDir = path.join(__dirname, '../temp');
if (!fs.existsSync(tempDir)) {
  fs.mkdirSync(tempDir, { recursive: true });
}

/**
 * Generate a confirmation form PDF for a booking
 * @param {Object} bookingData - The booking data
 * @returns {Promise<Buffer>} - PDF buffer
 */
async function generateConfirmationPDF(bookingData) {
  return new Promise((resolve, reject) => {
    try {
      const doc = new PDFDocument({
        size: 'A4',
        margin: 40,
        bufferPages: true
      });

      const chunks = [];

      doc.on('data', (chunk) => {
        chunks.push(chunk);
      });

      doc.on('end', () => {
        resolve(Buffer.concat(chunks));
      });

      doc.on('error', reject);

      // Header with hospital name
      doc.fontSize(24).font('Helvetica-Bold').text('EMERGENCY BED BOOKING', {
        align: 'center'
      });
      doc.fontSize(14).font('Helvetica').text('CONFIRMATION FORM', {
        align: 'center'
      });

      doc.moveDown();
      doc.strokeColor('#000000').moveTo(40, doc.y).lineTo(550, doc.y).stroke();
      doc.moveDown();

      // Confirmation Header
      doc.fontSize(12).font('Helvetica-Bold').text('BOOKING CONFIRMATION', {
        underline: true
      });
      doc.fontSize(10).font('Helvetica');
      doc.text(`Confirmation Date: ${new Date(bookingData.confirmationDate).toLocaleDateString('en-IN', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
      })}`, { width: 470 });
      doc.text(`Confirmation ID: ${bookingData.confirmationId}`, { width: 470 });
      doc.text(`Booking ID: ${bookingData.bookingId}`, { width: 470 });

      doc.moveDown();

      // Hospital Information Section
      doc.fontSize(12).font('Helvetica-Bold').text('HOSPITAL INFORMATION', {
        underline: true
      });
      doc.fontSize(10).font('Helvetica');
      doc.text(`Hospital Name: ${bookingData.hospitalName}`, { width: 470 });
      doc.text(`Address: ${bookingData.hospitalAddress}`, { width: 470 });
      doc.text(`City/District: ${bookingData.hospitalCity}`, { width: 470 });
      doc.text(`Emergency Contact: ${bookingData.hospitalPhone}`, { width: 470 });
      doc.text(`Email: ${bookingData.hospitalEmail}`, { width: 470 });

      doc.moveDown();

      // Patient Information Section
      doc.fontSize(12).font('Helvetica-Bold').text('PATIENT INFORMATION', {
        underline: true
      });
      doc.fontSize(10).font('Helvetica');
      doc.text(`Patient Name: ${bookingData.patientName}`, { width: 470 });
      doc.text(`Age: ${bookingData.patientAge} years`, { width: 470 });
      doc.text(`Gender: ${bookingData.patientGender}`, { width: 470 });
      doc.text(`Contact Phone: ${bookingData.contactPhone}`, { width: 470 });
      doc.text(`Email: ${bookingData.contactEmail || 'N/A'}`, { width: 470 });

      doc.moveDown();

      // Medical Information Section
      doc.fontSize(12).font('Helvetica-Bold').text('MEDICAL INFORMATION', {
        underline: true
      });
      doc.fontSize(10).font('Helvetica');
      doc.text(`Emergency Type: ${bookingData.emergencyType}`, { width: 470 });
      doc.text(`Medical Condition: ${bookingData.medicalCondition}`, { width: 470 });

      doc.moveDown();

      // Important Notes Section
      doc.fontSize(12).font('Helvetica-Bold').text('IMPORTANT NOTES', {
        underline: true
      });
      doc.fontSize(9).font('Helvetica');
      doc.text('1. Please keep this confirmation for your records.', { width: 470 });
      doc.text('2. Contact the hospital at the above number to confirm your arrival.', { width: 470 });
      doc.text('3. Bring a valid ID and insurance documents if applicable.', { width: 470 });
      doc.text('4. In case of emergency, call the hospital emergency number immediately.', { width: 470 });

      doc.moveDown();
      doc.strokeColor('#000000').moveTo(40, doc.y).lineTo(550, doc.y).stroke();
      doc.moveDown();

      // Footer
      doc.fontSize(8).font('Helvetica').text(
        'Your booking has been successfully confirmed! A bed has been reserved for you at the hospital. Please contact the hospital at the emergency number above to confirm your arrival time.',
        {
          align: 'center',
          width: 470
        }
      );

      doc.moveDown(0.5);
      doc.fontSize(8).text(`Generated on: ${new Date().toLocaleString('en-IN')}`, {
        align: 'center',
        width: 470
      });

      doc.end();
    } catch (error) {
      reject(error);
    }
  });
}

module.exports = {
  generateConfirmationPDF,
  tempDir
};
