import ExcelJS from 'exceljs';
import { saveAs } from 'file-saver';

export const exportToExcel = async (data, filename = 'Generator_Report', sheetName = 'Report') => {
  const workbook = new ExcelJS.Workbook();
  const worksheet = workbook.addWorksheet(sheetName);

  if (data.length === 0) {
    alert("No data to export");
    return;
  }

  // Create columns based on object keys
  const columns = Object.keys(data[0]).map(key => ({
    header: key.replace(/_/g, ' ').toUpperCase(),
    key: key,
    width: 20
  }));
  worksheet.columns = columns;

  // Add rows
  data.forEach(item => worksheet.addRow(item));

  // Style header
  worksheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFFFF' } };
  worksheet.getRow(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF3B82F6' } };

  // Generate blob
  const buffer = await workbook.xlsx.writeBuffer();
  const blob = new Blob([buffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
  saveAs(blob, `${filename}_${new Date().toISOString().split('T')[0]}.xlsx`);
};

export const printToPDF = () => {
  window.print();
};
