module.exports = {
  env: {
    node: true,   // ✅ บอกว่าใช้ Node.js
  },
  extends: "eslint:recommended",
  rules: {
    // ปิด warning นี้ก็ได้ถ้าไม่อยากให้แจ้ง
    "no-unused-vars": "off"
  }
};
