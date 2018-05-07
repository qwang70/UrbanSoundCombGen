//Prior to writing code, make sure your TouchOSC app is set to send OSC messages to your computer's IP address, on port 57120.


(
// The outport and IP address for the computer
~semaphore = Semaphore.new(1);
~semaphoreForRemove = Semaphore.new(1);
w = Window.new("Urban Sound Combgen", Rect(400,400,400,400));
~initComp = CompositeView.new(w,Rect.newSides(30,30,400-30,400-30));
StaticText.new(~initComp,Rect.newSides(0,0,400-60, 30)).string_("Enter the IP address of your phone/iPad.").resize_(2);
~t1 = TextField.new(~initComp,Rect.newSides(0,40,400-60,70)).resize_(2);
~t1.value = "192.168.1.101";
b = Button.new(~initComp,Rect.newSides(145,80,195,110)).states_([["Enter"]]);
~t2 = StaticText(~initComp,Rect.newSides(120,120,220,150)).string_("");
b.action = {
	~myIP = ~t1.value;
	~adrs = NetAddr(~myIP, 58100);
	~t2.string = ~adrs.ip;
};
w.front;

// dictionary that maps the type of sound to the folder index
d = Dictionary.newFrom(List[
	0, Dictionary.newFrom(List[\children_playing,2]),
	1, Dictionary.newFrom(List[\dog_bark,3]),
	2,Dictionary.newFrom(List[\air_conditioner,0, \car_horn, 1, \drilling, 4,
		\engine_idling, 5, \gun_shot, 6, \jackhammer, 7, \siren, 8
	]),
	3, Dictionary.newFrom(List[\street_music, 9])]);

// function get a random sound file
~getRandomSoundFile = {
	arg folderPath;
	var allFiles,randFile;
	allFiles = folderPath.files;
	randFile = allFiles.choose;
	// choose a none csv/json file
	["randFile.fileName", randFile.fileName].postln;
	while ( { randFile.isNil || randFile.fileName.contains(".csv") ||  randFile.fileName.contains(".json")
		|| randFile.fileName.contains(".mp3")},
	{ randFile = allFiles.choose; });
	randFile;
};
~dirname = thisProcess.nowExecutingPath.dirname;
~dataPath = PathName.new(~dirname ++ "/data");
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
			"stereo channel".postln;
			~currSoundSynth[idx] = ~currSoundSynth[idx].add(
				Synth.new(\stereo_play, [\buf, buffer,
					\pan, ~elementPan[idx] + ~globalPanVol[0],
					\amp, ~elementVolume[idx] * ~globalPanVol[1]]));


		},
		{
			// mono channel
			"mono channel".postln;
			~currSoundSynth[idx] = ~currSoundSynth[idx].add(
				Synth.new(\mono_play, [\buf, buffer,
					\pan, ~elementPan[idx] + ~globalPanVol[0],
					\amp, ~elementVolume[idx]  * ~globalPanVol[1]]));
		}
		);
		~numSound[idx] = ~numSound[idx] + 1;
		["~numSound", ~numSound].postln;
		["~elementNoise",~elementNoise].postln;
	};

	// routine
	Routine{
		newFile =
		~getRandomSoundFile.value(~folderPath[d[type].choose]).fullPath;
		// add to history
		~soundFileHist[type] = ~soundFileHist[type].add(newFile);
		~filePlayTypeHist = ~filePlayTypeHist.add(type);
		// add to buffer
		buffer = Buffer.read(s, newFile);
		~currSoundBuff[type] = ~currSoundBuff[type].add(buffer);
		~adrs.sendMsg("/combGen/led" ++ (type+1), 1);
		s.sync; //wait for completion
		addBufSynthHelper.value(buffer, type);
	}.play;

};

// select random file and add to hist
~removeSound = {
	arg type;
	// add to history
	if( ~currSoundSynth[type].size > 0,
		{
			// fade out the sound
			Routine{
				["before sleep", type].postln;
				~currSoundSynth[type][0].set(\gate, 0);
				1.sleep;
				["after sleep", type].postln;
				// free & remove synth
				~currSoundSynth[type][0].free;
				~currSoundSynth[type].removeAt(0);

				["cleaned synth"].postln;
				// free & remove buffer
				~currSoundBuff[type][0].free;
				~currSoundBuff[type].removeAt(0);
				~numSound[type] = ~numSound[type] - 1;
				["after signal", ~semaphoreForRemove.count].postln;
				~semaphoreForRemove.signal;
				["after signal", ~semaphoreForRemove.count].postln;
			}.play;
		},{}
	);

};
// free all OSC def
OSCdef.freeAll;
s.waitForBoot({
	var noisenessHelper, panHelper, volumeHelper, addByNoise, removeByNoise;

	// helper function to add the sound by the noiseness
	addByNoise = {
		arg idx;
		for ( 1, ~elementNoise[idx],
			{
				~addNewSound.value(idx);
		} )
	};

	removeByNoise = {
		arg idx;
		var count = 0;
		{
			if(~numSound[idx] > 0, {
				for ( 1, ~elementNoise[idx],
					{
						arg i;
						~adrs.sendMsg("/combGen/led" ++ (idx+1), 1-((i-1)/~elementNoise[idx]));

						~removeSound.value(idx);
						1.wait;
						["before ~semaphoreForRemove release" ++ idx, i].postln;
						~semaphoreForRemove.wait;
						["before ~semaphoreForRemove release" ++ idx, i].postln;
						s.sync;

					};
				);
			}
			);

			// hardcoded...
			s.sync;
			~adrs.sendMsg("/combGen/led" ++ (idx+1), 0);
			("before semaphore release" ++ idx).postln;
			~semaphore.signal;
			("after semaphore release" ++ idx).postln;
		}.fork;
	};
	// helper function to adjust the noiseness
	noisenessHelper = {
		arg idx, msg;
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
									~addNewSound.value(idx);
							} )
						},
						{
							{
								// remove old sound if noiseness is smaller
								for ( 1, diff * (-1),
									{
										~removeSound.value(idx);
										1.wait;
								};

								);

							}.fork;
						};)
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
		arg buf, rate = 1, loop = 1, out = 0, pan = 0, amp = 1, gate = 1;
		var sig, env;
		sig = PlayBuf.ar(2, buf,
			BufRateScale.kr(buf) * rate, 1, 0, loop,
			doneAction: 0
		);
		env = EnvGen.kr(Env.adsr(2, 0.3, 1, 1), gate, doneAction:0);
		sig = sig * env * amp;
		sig = sig.collect{|chan|
			Pan2.ar(chan, pan)
		}.sum;
		Out.ar(out, sig);
	}
	).writeDefFile;

	SynthDef.new(\mono_play, {
		arg buf, rate = 1, loop = 1, out = 0, pan = 0, amp = 1, gate = 1;
		var sig, env;
		sig = PlayBuf.ar(1, buf,
			BufRateScale.kr(buf) * rate, 1, 0, loop,
			doneAction: 0
		);
		env = EnvGen.kr(Env.adsr(2, 0.3, 1, 1), gate, doneAction:0);
		sig = sig * env * amp;
		sig = Pan2.ar(sig, pan, 1);
		Out.ar(out, sig);
	}
	).writeDefFile;

	s.sync; //wait for completion

	//toggles
	OSCdef.new(
		\toggle1,
		{
			arg msg, time, addr, port;
			case
			{msg[1] == 0}
			{

				removeByNoise.value(0);

			}
			{msg[1] == 1}
			{
				addByNoise.value(0);
			}

		},
		'/combGen/toggle1'
	);

	OSCdef.new(
		\toggle2,
		{
			arg msg, time, addr, port;
			case
			{msg[1] == 0}
			{
				removeByNoise.value(1);

			}
			{msg[1] == 1}
			{

				addByNoise.value(1);
			}
		},
		'/combGen/toggle2'
	);

	OSCdef.new(
		\toggle3,
		{
			arg msg, time, addr, port;
			case
			{msg[1] == 0}
			{

				removeByNoise.value(2);

			}
			{msg[1] == 1}
			{

				addByNoise.value(2);
			}
		},
		'/combGen/toggle3'
	);

	OSCdef.new(
		\toggle4,
		{
			arg msg, time, addr, port;
			case
			{msg[1] == 0}
			{
				removeByNoise.value(3);

			}
			{msg[1] == 1}
			{

				addByNoise.value(3);
			}

		},
		'/combGen/toggle4'
	);
	//faders
	OSCdef.new(
		\fader1,
		{
			arg msg, time, addr, port;
			noisenessHelper.value(0, msg);
		},
		'/combGen/fader1'
	);
	OSCdef.new(
		\fader2,
		{
			arg msg, time, addr, port;
			noisenessHelper.value(1, msg);
		},
		'/combGen/fader2'
	);

	OSCdef.new(
		\fader3,
		{
			arg msg, time, addr, port;
			noisenessHelper.value(2, msg);
		},
		'/combGen/fader3'
	);
	OSCdef.new(
		\fader4,
		{
			arg msg, time, addr, port;
			noisenessHelper.value(3, msg);
		},
		'/combGen/fader4'
	);
	//pans
	OSCdef.new(
		\rotaryPan1,
		{
			arg msg, time, addr, port;
			// scale from [0,1] to [-1,1]
			panHelper.value(0, msg);
		},
		'/combGen/rotaryPan1'
	);
	OSCdef.new(
		\rotaryPan2,
		{
			arg msg, time, addr, port;
			// scale from [0,1] to [-1,1]
			panHelper.value(1, msg);

		},
		'/combGen/rotaryPan2'
	);
	OSCdef.new(
		\rotaryPan3,
		{
			arg msg, time, addr, port;
			// scale from [0,1] to [-1,1]
			panHelper.value(2, msg);

		},
		'/combGen/rotaryPan3'
	);
	OSCdef.new(
		\rotaryPan4,
		{
			arg msg, time, addr, port;
			// scale from [0,1] to [-1,1]
			panHelper.value(3, msg);
		},
		'/combGen/rotaryPan4'
	);
	//volumes
	OSCdef.new(
		\rotaryVolume1,
		{
			arg msg, time, addr, port;
			volumeHelper.value(0, msg);
		},
		'/combGen/rotaryVolume1'
	);
	OSCdef.new(
		\rotaryVolume2,
		{
			arg msg, time, addr, port;
			volumeHelper.value(1, msg);
		},
		'/combGen/rotaryVolume2'
	);
	OSCdef.new(
		\rotaryVolume3,
		{
			arg msg, time, addr, port;
			volumeHelper.value(2, msg);
		},
		'/combGen/rotaryVolume3'
	);
	OSCdef.new(
		\rotaryVolume4,
		{
			arg msg, time, addr, port;
			volumeHelper.value(3, msg);
		},
		'/combGen/rotaryVolume4'
	);
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
	);
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
	);
	OSCdef.new(
		\reset,
		{
			arg msg, time, addr, port;
			if(msg[1] == 0, {
			"reset".postln;
				Routine {
					// clean all buff and synth
					"clean all buff and synth".postln;
					~elementNoise.postln;
					4.do({|i|
						removeByNoise.value(i);
						("before semaphore wait" ++ i).postln;
						~semaphore.wait;
						("after semaphore wait" ++ i).postln;
					});
					s.sync;
					// reset Array values
					"initArrays".postln;
					~initArrays.value();
				}.play;
				// reset element each row
				["reset element each row"].postln;
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
			});

		},
		'/combGen/multipush1/1/1'
	);
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

				if(totalNumSound > 0, {
					// get the type of the last song playing
					type = block {|break|
						forBy(~filePlayTypeHist.size()-1, 0, -1,
							{
								arg i;
								var currType;
								// find the last sound playing
								currType = ~filePlayTypeHist[i];
								if(~numSound[currType] > 0,
									{
										tempNum = tempNum + 1;
								} );
								// check whether hit the last sound playing
								if(totalNumSound == tempNum,
									{break.value(currType)});
							}
						);
						break.value(nil);
					};

					if(type.notNil, {
						~removeSound.value(type);
						~addNewSound.value(type);
					});
				});
			});
		},
		'/combGen/multipush1/2/1'
	);
	OSCdef.new(
		\save,
		{
			arg msg, time, addr, port;
			fork{
				// var score, sndbuf, synth, options;
				var f, string;
				'save'.postln;
				string = "";
				// concatenate strings
				~currSoundBuff.do({
					arg item, idx1;
					item.do({
						arg buffer;
						string = string ++ (buffer.path ++ "," ++ (~elementPan[idx1] + ~globalPanVol[0])
							++ "," ++  (~elementVolume[idx1] * ~globalPanVol[1])
							++ "," ++  "\n");
					}
					)
				};
				f = File(~dirname ++ "/saved.text","w");
				f.write(string);
				f.close;
				)
				/*score = Score.new;

				// create a Buffer object for adding to the Score
				sndbuf = Buffer.new;

				// take human sound to test
				// for NRT rendering, the buffer messages must be added to the Score
				score.add([0, sndbuf.allocReadMsg(~currSoundBuff[0][0].path)]);
				sndbuf.postln;
				synth = Synth.basicNew(\stereo_play);

				// .newMsg(target, args, addAction: 'addToHead')
				score.add([0.2,
					synth.newMsg(z, [\buffer, sndbuf,
						\pan, ~elementPan[0] + ~globalPanVol[0],
						\amp, ~elementVolume[0] * ~globalPanVol[1]
				])]);
				// the dummy command. The soundfile will be 20 seconds long
				score.add([20, 0]);

				// the ServerOptions for rendering the soundfile
				options = ServerOptions.new.numOutputBusChannels_(2);
				// score.play(s);
				// write the soundfile out to disk
				score.recordNRT( ~dirname ++ "/saved.osc", ~dirname ++ "/saved.aiff", options: options);
				sndbuf.free;*/
			};
		},
		'/combGen/multipush1/3/1'
	);
});
)
s.boot;
s.plotTree;
s.freeAll
