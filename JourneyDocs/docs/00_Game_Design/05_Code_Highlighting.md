Highlight.js highlights syntax in code examples on blogs, forums and in fact on any web pages. It's very easy to use because it works automatically: finds blocks of code, detects a language, highlights it. [Learn more.](http://softwaremaniacs.org/soft/highlight/en/)

**C**

	// Fire whenever the user has joined the room
	void OnJoinedRoom () {
		Debug.Log ("Joined room!");
		//Spawn the player into the world
		GameObject player = PhotonNetwork.Instantiate(playerPrefab.name, Vector3.up * 5, Quaternion.identity, 0);
		//Set a camera to follow the player
		GameObject.Find ("PlayerCamera").GetComponent<SmoothFollow> ().target = player.transform;
	}
