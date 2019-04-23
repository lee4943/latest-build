/* 
  Exposed function for use with express route.
  Calls 'findLatestBuild(payload.jobs)' to actually
  pull out the latest build and return it
*/
function getLatestBuild(req, res) {
    const jobsBlob = req.body;
    const latestBuild = findLatestBuild(jobsBlob.jobs);
    res.json(latestBuild);
}

/*
  Pulls out latest build from 'jobs' JSON blob!
  Loops through the 'Builds' array within
  all jobs in 'jobs' to find the latest build
  among them
*/
function findLatestBuild(jobs) {
    let latestBuild = { 
        latest: {
            build_date: "0",
            ami_id: "",
            commit_hash: ""
        } 
    };

    for (const job in jobs) {
        let builds = jobs[job]["Builds"];
        for (let i = 0; i < builds.length; i++) {
            let build = builds[i];
            if (parseInt(build.build_date) > parseInt(latestBuild.latest.build_date)) {
                let outputArr = build.output.split(" ");
                latestBuild.latest = {
                    build_date: build.build_date,
                    ami_id: outputArr[2],
                    commit_hash: outputArr[3]
                }
            }
        }
    }
    return latestBuild;
}

// Makes the 'getLatestBuild' function available via 'require'
module.exports = {
    getLatestBuild
};