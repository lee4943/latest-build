// Express-related node modules
const express = require("express");
const app = express();
const bodyParser = require("body-parser");

// Custom consts
const port = 3000;
const buildFunctions = require("./build_functions");

// Express middleware
app.use(bodyParser.json());

// Health check
app.get("/health_check", (req, res) => {
    res.sendStatus(200).end();
});

// Main express route
app.post("/builds", buildFunctions.getLatestBuild);

// Start server on previously-specified port
app.listen(port, () => {
    console.log(`Running on port ${port}`);
});