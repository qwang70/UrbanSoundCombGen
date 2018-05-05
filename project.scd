//Prior to writing code, make sure your TouchOSC app is set to send OSC messages to your computer's IP address, on port 57120.

(
//initialize global variables
~numElements = Array.fill(4,0);
// 0: numHuman; 1: numNature; 2: numMechanic; 3: numMusic;

// dictionary that maps the type of sound to the folder index
d = Dictionary.newFrom(List[\human, Dictionary.newFrom(List[\children_playing,2]),
	\nature, Dictionary.newFrom(List[\dog_bark,3]),
	\mechanic,Dictionary.newFrom(List[\air_conditioner,0, \car_horn, 1, \drilling, 4,
		\engine_idling, 5, \gun_shot, 6, \jackhammer, 7, \siren, 8
	]),
	\music, Dictionary.newFrom(List[\street_music, 9])]);

// function get a random sound file
~getRandomSoundFile = {
	arg folderPath;
	var allFiles,randFile;
	allFiles = folderPath.files;
	randFile = allFiles.choose;
	// choose a none csv/json file
	// TODO: Install quarks? Quarks.install('MP3');
	while ( { randFile.fileName.contains(".csv") ||  randFile.fileName.contains(".json")
		|| randFile.fileName.contains(".mp3")},
	{ randFile = allFiles.choose; });
	randFile;
};

~dataPath = PathName.new("/Users/wangqiwen/Downloads/UrbanSound/data");
~folderPath = ~dataPath.folders;

// initiate file history
//TODO: or just a linked list
~humanFileHist = Array.new();
~natureFileHist = Array.new();
~mechanicFileHist = Array.new();
~musicFileHist = Array.new();

// add files to the history type
~filePlayTypeHist = Array.new();

// initiate file buffer list
~currHumanBuff = Array.new();
~currNatureBuff = Array.new();
~currMechanicBuff = Array.new();
~currMusicBuff = Array.new();
// initiate file synth list
~currHumanSynth = Array.new();
~currNatureSynth = Array.new();
~currMechanicSynth = Array.new();
~currMusicSynth = Array.new();

// noiseness
~elementNoise = Array.fill(4, 1);
~elementPan = Array.fill(4, 0);
~elementVolume = Array.fill(4, 1);

~globalPanVol = Array.fill(2, 0.5);

//current buffer that is playing
//boot the SC audio server
// select random file and add to hist
~addNewSound = {
	arg type;
	var newFile, buffer;
	["add new sound", type].postln;
	// add to history
	switch (type)
	{\human}   {
		// routine
		Routine{
			newFile = ~getRandomSoundFile.value(~folderPath[d[\human].choose]).fullPath;
			~humanFileHist = ~humanFileHist.add(newFile);
			// add to buffer
			buffer = Buffer.read(s, newFile);
			~currHumanBuff = ~currHumanBuff.add(buffer);
			s.sync; //wait for completion
			["numchannel", buffer.numChannels].postln;
			if(buffer.numChannels == 2, {
				// stereo channel
				"stereo channel".postln;
				~currHumanSynth = ~currHumanSynth.add(
					Synth.new(\stereo_play, [\buf, buffer,
						\pan, ~elementPan[0] + ~globalPanVol[0],
						\amp, ~elementVolume[0] * ~globalPanVol[1]]));


			},
			{
				// mono channel
				"mono channel".postln;
				~currHumanSynth = ~currHumanSynth.add(
					Synth.new(\mono_play, [\buf, buffer,
						\pan, ~elementPan[0] + ~globalPanVol[0],
						\amp, ~elementVolume[0]  * ~globalPanVol[1]]));
			}
			);
			~numElements[0] = ~numElements[0] + 1;


			}.play;


	}
	{\nature} {
	Routine{
		newFile = ~getRandomSoundFile.value(~folderPath[d[\nature].choose]).fullPath;
		~natureFileHist = ~natureFileHist.add(newFile);
		// add to buffer
		buffer = Buffer.read(s, newFile);
		~currNatureBuff = ~currNatureBuff.add(buffer);
		s.sync; //wait for completion
		if(buffer.numChannels == 2, {
			// stereo channel
			"stereo channel".postln;
			~currNatureSynth = ~currNatureSynth.add(
				Synth.new(\stereo_play, [\buf, buffer,
					\pan, ~elementPan[1] + ~globalPanVol[0],
					\amp, ~elementVolume[1] * ~globalPanVol[1] ])
			);

		},
		{
			// mono channel
			"mono channel".postln;
			~currNatureSynth = ~currNatureSynth.add(
				Synth.new(\mono_play, [\buf, buffer,
					\pan, ~elementPan[1] + ~globalPanVol[0],
					\amp, ~elementVolume[1]  * ~globalPanVol[1]])
			);

		});
		~numElements[1] = ~numElements[1] + 1;
		["~numElements[1]", ~numElements[1]].postln;
	}.play;

	}
	{\mechanic} {
		Routine{
			newFile = ~getRandomSoundFile.value(~folderPath[d[\mechanic].choose]).fullPath;
			~mechanicFileHist = ~mechanicFileHist.add(newFile);
			// add to buffer
			buffer = Buffer.read(s, newFile);
			~currMechanicBuff = ~currMechanicBuff.add(buffer);
			s.sync; //wait for completion
			if(buffer.numChannels == 2, {
				// stereo channel
				"stereo channel".postln;
				~currMechanicSynth = ~currMechanicSynth.add(
					Synth.new(\stereo_play, [\buf, buffer,
						\pan, ~elementPan[2] + ~globalPanVol[0],
						\amp, ~elementVolume[2] * ~globalPanVol[1] ])
				);

			},
			{
				// mono channel
				"mono channel".postln;
				~currMechanicSynth = ~currMechanicSynth.add(
					Synth.new(\mono_play, [\buf, buffer,
						\pan, ~elementPan[2] + ~globalPanVol[0],
						\amp, ~elementVolume[2]  * ~globalPanVol[1]])
				);

			});

			~numElements[2] = ~numElements[2] + 1;
			["~numElements[2]", ~numElements[2]].postln;
		}.play;
	}
	{\music} {
		Routine{
			newFile = ~getRandomSoundFile.value(~folderPath[d[\music].choose]).fullPath;
			~musicFileHist = ~musicFileHist.add(newFile);
			// add to buffer
			buffer = Buffer.read(s, newFile);
			~currMusicBuff = ~currMusicBuff.add(buffer);
			s.sync; //wait for completion
			if(buffer.numChannels == 2, {
				// stereo channel
				"stereo channel".postln;
				~currMusicSynth = ~currMusicSynth.add(
					Synth.new(\stereo_play, [\buf, buffer,
						\pan, ~elementPan[3] + ~globalPanVol[0],
						\amp, ~elementVolume[3] * ~globalPanVol[1] ])
				);

			},
			{
				// mono channel
				"mono channel".postln;
				~currMusicSynth = ~currMusicSynth.add(
					Synth.new(\mono_play, [\buf, buffer,
						\pan, ~elementPan[3] + ~globalPanVol[0],
						\amp, ~elementVolume[3]  * ~globalPanVol[1]])
				);

			});

			~numElements[3] = ~numElements[3] + 1;
		}.play;
	};
};

// select random file and add to hist
~removeSound = {
	arg type;
	var newFile;
	["remove new sound", type].postln;
	// add to history
	switch (type)
	{\human}   {
		if( ~currHumanSynth.size > 0,
			{
				// free & remove synth
				~currHumanSynth[0].free;
				~currHumanSynth.removeAt(0);

				// free & remove buffer
				~currHumanBuff[0].free;
				~currHumanBuff.removeAt(0);
				~numElements[0] = ~numElements[0] - 1;

				["~numElements[0]", ~numElements[0]].postln;
			},{}
		);
	}
	{\nature} {
		~currNatureSynth.size.postln;
		if( ~currNatureSynth.size > 0,
			{
				// free & remove synth
				~currNatureSynth[0].free;
				~currNatureSynth.removeAt(0);

				// free & remove buffer
				~currNatureBuff[0].free;
				~currNatureBuff.removeAt(0);
				~numElements[1] = ~numElements[1] - 1;

			}, {}
		);

	}
	{\mechanic} {
		if( ~currMechanicSynth.size > 0,
			{
				// free & remove synth
				~currMechanicSynth[0].free;
				~currMechanicSynth.removeAt(0);

				// free & remove buffer
				~currMechanicBuff[0].free;
				~currMechanicBuff.removeAt(0);
				~numElements[2] = ~numElements[2] - 1;
				["~numElements[2]", ~numElements[2]].postln;
			}, {}
		);
	}
	{\music} {
		if( ~currMusicSynth.size > 0,
			{
				// free & remove synth
				~currMusicSynth[0].free;
				~currMusicSynth.removeAt(0);

				// free & remove buffer
				~currMusicBuff[0].free;
				~currMusicBuff.removeAt(0);
				~numElements[3] = ~numElements[3] - 1;
	})};

};

s.waitForBoot({
	var noisenessHelper;

	//create and add SynthDefs
	//create & add buffer-playing SynthDef
	SynthDef.new(\stereo_play, {
		arg buf, rate = 1, loop = 1, out = 0, pan = 0, amp = 1;
		var sig;
		sig = PlayBuf.ar(2, buf,
			BufRateScale.kr(buf) * rate, 1, 0, loop,
			doneAction: 0
		);
		amp.postln;
		sig = sig * amp;
		sig = sig.collect{|chan|
			Pan2.ar(chan, pan)
		}.sum;
		Out.ar(out, sig);
	}
	).add;

		SynthDef.new(\mono_play, {
		arg buf, rate = 1, loop = 1, out = 0, pan = 0, amp = 1;
		var sig;
		sig = PlayBuf.ar(1, buf,
			BufRateScale.kr(buf) * rate, 1, 0, loop,
			doneAction: 0
		);
		amp.postln;
		sig = sig * amp;
		sig = Pan2.ar(sig, pan, 1);
		Out.ar(out, sig);
	}
	).add;

	s.sync; //wait for completion

	//toggles
	OSCdef.new(
		\toggle1,
		{
			arg msg, time, addr, port;
			msg.postln;
			case
			{msg[1] == 0}
			{
				for ( 1, ~elementNoise[0],
					{
						~removeSound.value(\human);
				} )

			}
			{msg[1] == 1}
			{
				for ( 1, ~elementNoise[0],
					{
						~addNewSound.value(\human);
				} )
			}

		},
		'/combGen/toggle1'
	).add;

	OSCdef.new(
		\toggle2,
		{
			arg msg, time, addr, port;
			["toggle2", msg].postln;
			case
			{msg[1] == 0}
			{
				for ( 1, ~elementNoise[1],
					{
						~removeSound.value(\nature);
				} )

			}
			{msg[1] == 1}
			{
				for ( 1, ~elementNoise[1],
					{
						~addNewSound.value(\nature);
				} )
			}
		},
		'/combGen/toggle2'
	).add;

	OSCdef.new(
		\toggle3,
		{
			arg msg, time, addr, port;
			["toggle3", msg].postln;
			case
			{msg[1] == 0}
			{
				for ( 1, ~elementNoise[2],
					{
						~removeSound.value(\mechanic);
				} )

			}
			{msg[1] == 1}
			{
				for ( 1, ~elementNoise[2],
					{
						~addNewSound.value(\mechanic);
				} )
			}
		},
		'/combGen/toggle3'
	).add;

	OSCdef.new(
		\toggle4,
		{
			arg msg, time, addr, port;
			["toggle4", msg].postln;
			case
			{msg[1] == 0}
			{
				for ( 1, ~elementNoise[3],
					{
						~removeSound.value(\music);
				} )

			}
			{msg[1] == 1}
			{
				for ( 1, ~elementNoise[3],
					{
						~addNewSound.value(\music);
				} )
			}

		},
		'/combGen/toggle4'
	).add;
	//faders
	OSCdef.new(
		\fader1,
		{
			arg msg, time, addr, port;
			var diff;
			if(~elementNoise[0] != msg[1].round(1),
				{
					diff = msg[1].round(1) - ~elementNoise[0];
					~elementNoise[0] = msg[1].round(1);
					["~elementNoise[0]", msg[1].round(1),
						"diff", diff, "~numElements[0]", ~numElements[0]].postln;
					if(~numElements[0] > 0,
						{
							if(diff > 0, {
								for ( 1, diff,
									{
										"plus 1".postln;
										~addNewSound.value(\human);
								} )
							},
							{
								for ( 1, diff * (-1),
									{
										"minus 1".postln;
										~removeSound.value(\human);
								} )
							})
						}
					)

			});
		},
		'/combGen/fader1'
	).add;
	OSCdef.new(
		\fader2,
		{
			arg msg, time, addr, port;
			var diff;
			if(~elementNoise[1] != msg[1].round(1),
				{
					diff = msg[1].round(1) - ~elementNoise[1];
					~elementNoise[1] = msg[1].round(1);
					if(~numElements[1] > 0,
						{
							if(diff > 0, {
								for ( 1, diff,
									{
										~addNewSound.value(\nature);
								} )
							},
							{
								for ( 1, diff * (-1),
									{
										~removeSound.value(\nature);
								} )
							})
						}
					)

			});
		},
		'/combGen/fader2'
	).add;

	OSCdef.new(
		\fader3,
		{
			arg msg, time, addr, port;
			var diff;
			if(~elementNoise[2] != msg[1].round(1),
				{
					diff = msg[1].round(1) - ~elementNoise[2];
					~elementNoise[2] = msg[1].round(1);
					if(~numElements[2] > 0,
						{
							if(diff > 0, {
								for ( 1, diff,
									{
										~addNewSound.value(\mechanic);
								} )
							},
							{
								for ( 1, diff * (-1),
									{
										~removeSound.value(\mechanic);
								} )
							})
						}
					)

			});
		},
		'/combGen/fader3'
	).add;
	OSCdef.new(
		\fader4,
		{
			arg msg, time, addr, port;
			var diff;
			if(~elementNoise[3] != msg[1].round(1),
				{
					diff = msg[1].round(1) - ~elementNoise[3];
					~elementNoise[3] = msg[1].round(1);
					if(~numElements[3] > 0,
						{
							if(diff > 0, {
								for ( 1, diff,
									{
										~addNewSound.value(\music);
								} )
							},
							{
								for ( 1, diff * (-1),
									{
										~removeSound.value(\music);
								} )
							})
						}
					)

			});
		},
		'/combGen/fader4'
	).add;
	//pans
	OSCdef.new(
		\rotaryPan1,
		{
			arg msg, time, addr, port;
			// scale from [0,1] to [-1,1]
			~elementPan[0] = msg[1]*2-1;
			msg.postln;
			~currHumanSynth.size.postln;
			~currHumanSynth.do({
				arg item, i;
				["change pan", i, ~elementPan[0] + ~globalPanVol[0]];
				item.set(
				\pan, ~elementPan[0] + ~globalPanVol[0])
			});
		},
		'/combGen/rotaryPan1'
	).add;
	OSCdef.new(
		\rotaryPan2,
		{
			arg msg, time, addr, port;
			// scale from [0,1] to [-1,1]
			~elementPan[1] = msg[1]*2-1;
			~currNatureSynth.do({ arg item; item.set(
				\pan, ~elementPan[1] + ~globalPanVol[0]) });

		},
		'/combGen/rotaryPan2'
	).add;
	OSCdef.new(
		\rotaryPan3,
		{
			arg msg, time, addr, port;
			// scale from [0,1] to [-1,1]
			~elementPan[2] = msg[1]*2-1;
			~currMechanicSynth.do({ arg item; item.set(
				\pan, ~elementPan[2] + ~globalPanVol[0]) });

		},
		'/combGen/rotaryPan3'
	).add;
	OSCdef.new(
		\rotaryPan4,
		{
			arg msg, time, addr, port;
			// scale from [0,1] to [-1,1]
			~elementPan[3] = msg[1]*2-1;
			~currMusicSynth.do({ arg item; item.set(
				\pan, ~elementPan[3] + ~globalPanVol[0]) });

		},
		'/combGen/rotaryPan4'
	).add;
	//volumes
	OSCdef.new(
		\rotaryVolume1,
		{
			arg msg, time, addr, port;
			// scale from [0,1] to [0,2]
			~elementVolume[0] = msg[1]*2;
			~currHumanSynth.do({ arg item; item.set(
				\amp, ~elementVolume[0] * ~globalPanVol[1]) });
		},
		'/combGen/rotaryVolume1'
	).add;
	OSCdef.new(
		\rotaryVolume2,
		{
			arg msg, time, addr, port;
			// scale from [0,1] to [0,2]
			~elementVolume[1] = msg[1]*2;
			~currNatureSynth.do({ arg item; item.set(
				\amp, ~elementVolume[1] * ~globalPanVol[1]) });
		},
		'/combGen/rotaryVolume2'
	).add;
	OSCdef.new(
		\rotaryVolume3,
		{
			arg msg, time, addr, port;
			// scale from [0,1] to [0,2]
			~elementVolume[2] = msg[1]*2;
			~currMechanicSynth.do({ arg item; item.set(
				\amp, ~elementVolume[2] * ~globalPanVol[1]) });
		},
		'/combGen/rotaryVolume3'
	).add;
	OSCdef.new(
		\rotaryVolume4,
		{
			arg msg, time, addr, port;
			// scale from [0,1] to [0,2]
			~elementVolume[3] = msg[1]*2;
			~currMusicSynth.do({ arg item; item.set(
				\amp, ~elementVolume[3] * ~globalPanVol[1]) });
		},
		'/combGen/rotaryVolume4'
	).add;
	OSCdef.new(
		\globalpan,
		{
			arg msg, time, addr, port;
			~globalPanVol[0] = msg[1]*2 - 1;
			[~elementPan[0], ~globalPanVol[0], ~elementPan[0] + ~globalPanVol[0]].postln;
			~currHumanSynth.do({ arg item; item.set(
				\pan, ~elementPan[0] + ~globalPanVol[0]) });
			~currNatureSynth.do({ arg item; item.set(
				\pan, ~elementPan[1] + ~globalPanVol[0]) });
			~currMechanicSynth.do({ arg item; item.set(
				\pan, ~elementPan[2] + ~globalPanVol[0]) });
			~currMusicSynth.do({ arg item; item.set(
				\pan, ~elementPan[3] + ~globalPanVol[0]) });
		},
		'/combGen/multifader1/1'
	).add;
	OSCdef.new(
		\globalvolume,
		{
			arg msg, time, addr, port;
			~globalPanVol[1] = msg[1];
			~currHumanSynth.do({ arg item; item.set(
				\amp, ~elementVolume[0] * ~globalPanVol[1]) });
			~currNatureSynth.do({ arg item; item.set(
				\amp, ~elementVolume[1] * ~globalPanVol[1]) });
			~currMechanicSynth.do({ arg item; item.set(
				\amp, ~elementVolume[2] * ~globalPanVol[1]) });
			~currMusicSynth.do({ arg item; item.set(
				\amp, ~elementVolume[3] * ~globalPanVol[1]) });
		},
		'/combGen/multifader1/2'
	).add;
	OSCdef.new(
		\prev,
		{
			arg msg, time, addr, port;
			msg.postln;
		},
		'/combGen/multipush1/1/1'
	).add;
	OSCdef.new(
		\next,
		{
			arg msg, time, addr, port;
			'next'.postln;
		},
		'/combGen/multipush1/2/1'
	).add;
	OSCdef.new(
		\save,
		{
			arg msg, time, addr, port;
			'save'.postln;
		},
		'/combGen/multipush1/3/1'
	).add;
});
)

s.freeAll