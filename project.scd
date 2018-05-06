//Prior to writing code, make sure your TouchOSC app is set to send OSC messages to your computer's IP address, on port 57120.

(
// The outport and IP address for the computer
~adrs = NetAddr("10.194.20.26", 58100);

// dictionary that maps the type of sound to the folder index
d = Dictionary.newFrom(List[
	0, Dictionary.newFrom(List[\children_playing,2]),
	1, Dictionary.newFrom(List[\dog_bark,3]),
	2,Dictionary.newFrom(List[\air_conditioner,0, \car_horn, 1, \drilling, 4,
		\engine_idling, 5, \gun_shot, 6, \jackhammer, 7, \siren, 8
	]),
	3, Dictionary.newFrom(List[\street_music, 9])]);
~typeToIdx = Dictionary.newFrom(List[\human, 0, \nature, 1, \mechanic, 2, \music, 3]);

// function get a random sound file
~getRandomSoundFile = {
	arg folderPath;
	var allFiles,randFile;
	allFiles = folderPath.files;
	randFile = allFiles.choose;
	// choose a none csv/json file
	while ( { randFile.fileName.contains(".csv") ||  randFile.fileName.contains(".json")
		|| randFile.fileName.contains(".mp3")},
	{ randFile = allFiles.choose; });
	randFile;
};

~dataPath = PathName.new("/Users/wangqiwen/Downloads/UrbanSound/data");
~folderPath = ~dataPath.folders;

~initArrays = {
	//initialize global variables
	~numSound = Array.fill(4,0);
	// 0: numHuman; 1: numNature; 2: numMechanic; 3: numMusic;


	// initiate file history
	~soundFileHist = Array.with(Array.new(),Array.new(),Array.new(),Array.new());
	// 1:humanFileHist; 2: natureFileHist; 3: mechanicFileHist; 4: musicFileHist

	// add files to the history type
	~filePlayTypeHist = Array.new();

	// initiate file buffer list
	~currSoundBuff = Array.with(Array.new(),Array.new(),Array.new(),Array.new());
	// 1:currHumanBuff; 2:currNatureBuff; 3:currMechanicBuff; 4: currMusicBuff;

	// initiate file synth list
	~currSoundSynth = Array.with(Array.new(),Array.new(),Array.new(),Array.new());
	// 1: currHumanSynth; 2: currNatureSynth; 3: currMechanicSynth; 4: currMusicSynth

	// initialize variables for noiseness, pan, and volume
	~elementNoise = Array.fill(4, 1);
	~elementPan = Array.fill(4, 0);
	~elementVolume = Array.fill(4, 1);
	~globalPanVol = Array.with(0, 0.5);
};

~initArrays.value();

//current buffer that is playing
//boot the SC audio server
// select random file and add to hist
~addNewSound = {
	arg type;
	var newFile, buffer, addBufSynthHelper;

	addBufSynthHelper = {
		arg buffer, idx;
		if(buffer.numChannels == 2, {
			// stereo channel
			~currSoundSynth[idx] = ~currSoundSynth[idx].add(
				Synth.new(\stereo_play, [\buf, buffer,
					\pan, ~elementPan[idx] + ~globalPanVol[0],
					\amp, ~elementVolume[idx] * ~globalPanVol[1]]));


		},
		{
			// mono channel
			~currSoundSynth[idx] = ~currSoundSynth[idx].add(
				Synth.new(\mono_play, [\buf, buffer,
					\pan, ~elementPan[idx] + ~globalPanVol[0],
					\amp, ~elementVolume[idx]  * ~globalPanVol[1]]));
		}
		);
		~numSound[idx] = ~numSound[idx] + 1;
		~numSound.postln;
	};

	["add new sound", type].postln;

	// add to history
	switch (type)
	{0}   {
		// routine
		Routine{
			newFile =
			~getRandomSoundFile.value(~folderPath[d[type].choose]).fullPath;
			~soundFileHist[type] = ~soundFileHist[type].add(newFile);
			~filePlayTypeHist = ~filePlayTypeHist.add(type);
			// add to buffer
			buffer = Buffer.read(s, newFile);
			~currSoundBuff[type] = ~currSoundBuff[type].add(buffer);
			~currSoundBuff[type].postln;
			s.sync; //wait for completion
			addBufSynthHelper.value(buffer, type);
		}.play;


	}
	{\nature} {
		Routine{
			newFile = ~getRandomSoundFile.value(~folderPath[d[\nature].choose]).fullPath;
			~soundFileHist[1] = ~soundFileHist[1].add(newFile);
			~filePlayTypeHist = ~filePlayTypeHist.add(\nature);
			// add to buffer
			buffer = Buffer.read(s, newFile);
			~currSoundBuff[1] = ~currSoundBuff[1].add(buffer);
			s.sync; //wait for completion
			addBufSynthHelper.value(buffer, 1);
		}.play;

	}
	{\mechanic} {
		Routine{
			newFile = ~getRandomSoundFile.value(~folderPath[d[\mechanic].choose]).fullPath;
			~soundFileHist[2] = ~soundFileHist[2].add(newFile);
			~filePlayTypeHist = ~filePlayTypeHist.add(\mechanic);
			// add to buffer
			buffer = Buffer.read(s, newFile);
			~currSoundBuff[2] = ~currSoundBuff[2].add(buffer);
			s.sync; //wait for completion
			addBufSynthHelper.value(buffer, 2);
		}.play;
	}
	{\music} {
		Routine{
			newFile = ~getRandomSoundFile.value(~folderPath[d[\music].choose]).fullPath;
			~soundFileHist[3] = ~soundFileHist[3].add(newFile);
			~filePlayTypeHist = ~filePlayTypeHist.add(\music);
			// add to buffer
			buffer = Buffer.read(s, newFile);
			~currSoundBuff[3] = ~currSoundBuff[3].add(buffer);
			s.sync; //wait for completion
			addBufSynthHelper.value(buffer, 3);
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
		if( ~currSoundSynth[0].size > 0,
			{
				// free & remove synth
				~currSoundSynth[0][0].free;
				~currSoundSynth[0].removeAt(0);

				// free & remove buffer
				~currSoundBuff[0][0].free;
				~currSoundBuff[0].removeAt(0);
				~numSound[0] = ~numSound[0] - 1;

				["~numSound[0]", ~numSound[0]].postln;
			},{}
		);
	}
	{\nature} {
		~currSoundSynth[1].size.postln;
		if( ~currSoundSynth[1].size > 0,
			{
				// free & remove synth
				~currSoundSynth[1][0].free;
				~currSoundSynth[1].removeAt(0);

				// free & remove buffer
				~currSoundBuff[1][0].free;
				~currSoundBuff[1].removeAt(0);
				~numSound[1] = ~numSound[1] - 1;

			}, {}
		);

	}
	{\mechanic} {
		if( ~currSoundSynth[2].size > 0,
			{
				// free & remove synth
				~currSoundSynth[2][0].free;
				~currSoundSynth[2].removeAt(0);

				// free & remove buffer
				~currSoundBuff[2][0].free;
				~currSoundBuff[2].removeAt(0);
				~numSound[2] = ~numSound[2] - 1;
				["~numSound[2]", ~numSound[2]].postln;
			}, {}
		);
	}
	{\music} {
		if( ~currSoundSynth[3].size > 0,
			{
				// free & remove synth
				~currSoundSynth[3][0].free;
				~currSoundSynth[3].removeAt(0);

				// free & remove buffer
				~currSoundBuff[3][0].free;
				~currSoundBuff[3].removeAt(0);
				~numSound[3] = ~numSound[3] - 1;
	})};

};

s.waitForBoot({
	var noisenessHelper, panHelper, volumeHelper;

	// helper function to adjust the noiseness
	noisenessHelper = {
		arg idx, msg, type;
		var diff;
		if(~elementNoise[idx] != msg[1].round(1),
			{
				diff = msg[1].round(1) - ~elementNoise[idx];

				// assign new value to the noiseness
				~elementNoise[idx] = msg[1].round(1);
				if(~numSound[idx] > 0,
					{
						if(diff > 0, {
							// add new sound if noiseness is larger
							for ( 1, diff,
								{
									~addNewSound.value(type);
							} )
						},
						{
							// remove old sound if noiseness is smaller
							for ( 1, diff * (-1),
								{
									~removeSound.value(type);
							} )
						})
					}
				);
		});
	};

	// helper function to adjust the pan
	panHelper = {
		arg idx, msg;
		~elementPan[idx] = msg[1]*2-1;
		~currSoundSynth[idx].do({
			arg item, i;
			item.set(
				\pan, ~elementPan[idx] + ~globalPanVol[0]);
		});
	};

	// helper function to adjust the volume
	volumeHelper = {
		arg idx, msg;
		~elementVolume[idx] = msg[1]*2;
		~currSoundSynth[idx].do({ arg item; item.set(
			\amp, ~elementVolume[idx] * ~globalPanVol[1]) });
	};

	//create and add SynthDefs
	//create & add buffer-playing SynthDef
	SynthDef.new(\stereo_play, {
		arg buf, rate = 1, loop = 1, out = 0, pan = 0, amp = 1;
		var sig;
		sig = PlayBuf.ar(2, buf,
			BufRateScale.kr(buf) * rate, 1, 0, loop,
			doneAction: 0
		);
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
			[msg, time, addr, port].postln;
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
			noisenessHelper.value(0, msg, \human);
		},
		'/combGen/fader1'
	).add;
	OSCdef.new(
		\fader2,
		{
			arg msg, time, addr, port;
			noisenessHelper.value(1, msg, \nature);
		},
		'/combGen/fader2'
	).add;

	OSCdef.new(
		\fader3,
		{
			arg msg, time, addr, port;
			noisenessHelper.value(2, msg, \mechanic);
		},
		'/combGen/fader3'
	).add;
	OSCdef.new(
		\fader4,
		{
			arg msg, time, addr, port;
			noisenessHelper.value(3, msg, \music);
		},
		'/combGen/fader4'
	).add;
	//pans
	OSCdef.new(
		\rotaryPan1,
		{
			arg msg, time, addr, port;
			// scale from [0,1] to [-1,1]
			panHelper.value(0, msg);
		},
		'/combGen/rotaryPan1'
	).add;
	OSCdef.new(
		\rotaryPan2,
		{
			arg msg, time, addr, port;
			// scale from [0,1] to [-1,1]
			msg.postln;
			panHelper.value(1, msg);

		},
		'/combGen/rotaryPan2'
	).add;
	OSCdef.new(
		\rotaryPan3,
		{
			arg msg, time, addr, port;
			// scale from [0,1] to [-1,1]
			panHelper.value(2, msg);

		},
		'/combGen/rotaryPan3'
	).add;
	OSCdef.new(
		\rotaryPan4,
		{
			arg msg, time, addr, port;
			// scale from [0,1] to [-1,1]
			panHelper.value(3, msg);
		},
		'/combGen/rotaryPan4'
	).add;
	//volumes
	OSCdef.new(
		\rotaryVolume1,
		{
			arg msg, time, addr, port;
			volumeHelper.value(0, msg);
		},
		'/combGen/rotaryVolume1'
	).add;
	OSCdef.new(
		\rotaryVolume2,
		{
			arg msg, time, addr, port;
			volumeHelper.value(1, msg);
		},
		'/combGen/rotaryVolume2'
	).add;
	OSCdef.new(
		\rotaryVolume3,
		{
			arg msg, time, addr, port;
			volumeHelper.value(2, msg);
		},
		'/combGen/rotaryVolume3'
	).add;
	OSCdef.new(
		\rotaryVolume4,
		{
			arg msg, time, addr, port;
			volumeHelper.value(3, msg);
		},
		'/combGen/rotaryVolume4'
	).add;
	OSCdef.new(
		\globalpan,
		{
			arg msg, time, addr, port;
			~globalPanVol[0] = msg[1]*2 - 1;
			~currSoundSynth.do({ arg item, i;
				item.do({ arg item; item.set(
					\pan, ~elementPan[i] + ~globalPanVol[0]) });
			});
		},
		'/combGen/multifader1/1'
	).add;
	OSCdef.new(
		\globalvolume,
		{
			arg msg, time, addr, port;
			~globalPanVol[1] = msg[1];
			~currSoundSynth.do({ arg item, i;
				item.do({ arg item; item.set(
					\amp, ~elementVolume[i] * ~globalPanVol[1]) });
			});
		},
		'/combGen/multifader1/2'
	).add;
	OSCdef.new(
		\reset,
		{
			arg msg, time, addr, port;
			msg.postln;
			// reset Array values
			~initArrays.value();
			// reset element each row
			4.do({|i|
				~adrs.sendMsg("/combGen/toggle" ++ (i+1), 0);
				~adrs.sendMsg("/combGen/fader" ++ (i+1), 1);
				~adrs.sendMsg("/combGen/rotaryPan" ++ (i+1), 0.5);
				~adrs.sendMsg("/combGen/rotaryVolume" ++ (i+1), 0.5);
			});
			// reset multifader
			2.do({|i|
				~adrs.sendMsg("/combGen/multifader1/" ++ (i+1), 0.5);
			});

		},
		'/combGen/multipush1/1/1'
	).add;
	OSCdef.new(
		\next,
		{
			arg msg, time, addr, port;
			var totalNumSound, type, tempNum;
			'next'.postln;
			if(msg[1] == 0, {

				// pop old sound
				totalNumSound = ~numSound.sum;
				tempNum = 0;
				["~filePlayTypeHist", ~filePlayTypeHist, ~filePlayTypeHist.size()].postln;
				if(totalNumSound > 0, {
					type = block {|break|
						forBy(~filePlayTypeHist.size()-1, 0, -1,
							{
								arg i;
								var currType;
								i.postln;
								currType = ~filePlayTypeHist[i];
								["currType", currType].postln;
								if(~numSound[~typeToIdx[currType]] > 0,
									{
										tempNum = tempNum + 1;
										["update temp", tempNum].postln;
								} );
								[tempNum, totalNumSound].postln;
								if(totalNumSound == tempNum,
									{break.value(currType)});
							}
						);
						break.value(nil);
					};
					type.postln;
					if(type.notNil, {
						["numSound", ~numSound, totalNumSound].postln;
						["old hist", ~filePlayTypeHist,~filePlayTypeHist.size() - totalNumSound,  type].postln;
						["type to add", type].postln;
						~removeSound.value(type);
						~addNewSound.value(type);
					});
				});
			});
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
s.plotTree;
s.freeAll