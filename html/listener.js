const APP = new Vue({
  el: '#app',
  data: {
    show : false,
    createLobbyActive: false,
    newLobbyName: "",
    newLobbyPassword: "",
    newLobbyMaxPlayersAmount: 1,
    newSelectedDungeon: null,
    selectDungeonActive: false,
    playerIdentifier: null,
    playerLobby: null,
    lobbies : null,
    inLobby : false,
    lobbySettingsIsOpen : false,
    localization : {},
    dungeons : [],
    targetLobby : {
      modalActive : false,
      password : "",
      lobbyData : null,
    },
  },

  methods: {
    SetNewSelectedDungeon(val) {
      this.newSelectedDungeon = val
      this.selectDungeonActive = false
    },
    SetLocalization(localization){
      this.localization = localization
      $.post("https://lucid-dungeon/ready")

    },
    SetDungeons(dungeons){
      this.dungeons = dungeons
    },
    OpenUI(){
      this.show = true
    },
    CloseUI(){
      $.post("https://lucid-dungeon/close")
      this.show = false
    },
    SetPlayerLobby(val, inLobby) {
      this.playerLobby = val
      this.inLobby = inLobby
    },
    OpenLobbySettings(){
      this.lobbySettingsIsOpen = true
    },
    SetLobbies(val){

      this.lobbies = val
      if(val){
        this.lobbies.sort(function(a, b){
          if(a.label < b.label) { return -1; }
          if(a.label > b.label) { return 1; }
          return 0;
        })
      }
    },
    SetPlayerIdentifier(val) {
      this.playerIdentifier = val
    },
    PassLeadership(source){
      $.post("https://lucid-dungeon/passLeadership", JSON.stringify({
        source : source,
      }))
    },
    StartDungeon(){
      $.post("https://lucid-dungeon/startDungeon")
    },  
    JoinLobby(lobbyData, isLocked){
      if(isLocked){
        this.targetLobby.lobbyData = lobbyData
        this.targetLobby.modalActive = true
      }else{
        $.post("https://lucid-dungeon/joinLobby", JSON.stringify({
          lobbyId : lobbyData.id
        }))
      }
      
    },
    SetCreateLobbyIsActive(val) {
      this.createLobbyActive = val
      if (!val) {
        this.newSelectedDungeon = null
        this.newLobbyName = ""
        this.newLobbyPassword = ""
      }
    },
    KickPlayer(source){
      $.post("https://lucid-dungeon/kickPlayer", JSON.stringify({
        source : source,
      }))

    },  
    LeaveFromLobby(){
      $.post("https://lucid-dungeon/leaveFromLobby")
    },
    DeleteLobby(){
      $.post("https://lucid-dungeon/deleteLobby")
    },
    JoinLobbyWithPassword(){
      $.post("https://lucid-dungeon/joinLobby", JSON.stringify({
        lobbyId : this.targetLobby.lobbyData.id,
        password : this.targetLobby.password
      }), (success) =>{
        if(success){
          this.targetLobby.modalActive = false
          this.targetLobby.password = ''
          this.targetLobby.lobbyData = null
        }

      })

    },
    CreateLobby() {

      $.post("https://lucid-dungeon/createLobby", JSON.stringify({
        lobbyName: this.newLobbyName,
        lobbyPassword: this.newLobbyPassword,
        selectedDungeon: this.newSelectedDungeon,
        maxPlayersAmount : this.newLobbyMaxPlayersAmount,
      }), (success) =>{
        if(success){
          this.SetCreateLobbyIsActive(false)
          this.newSelectedDungeon = null
          this.newLobbyName = ""
          this.newLobbyPassword = ""
        }
      })

    },
    ChangeLobbySettings(){
      $.post("https://lucid-dungeon/changeLobbySettings", JSON.stringify({
        lobbyName: this.newLobbyName,
        lobbyPassword: this.newLobbyPassword,
        selectedDungeon: this.newSelectedDungeon,
        maxPlayersAmount : this.newLobbyMaxPlayersAmount,
      }), (success) =>{
        if(success){
          this.lobbySettingsIsOpen = false
          this.newSelectedDungeon = null
          this.newLobbyName = ""
          this.newLobbyPassword = ""
        }
      })
    }
  },
  computed: {

    GetSelectedDungeonLabel() {
      if (this.selectDungeonActive) {
        return this.localization["CLOSE"]
      } else {
        if (this.newSelectedDungeon == null) {
          return this.localization["SELECT"]
        } else {
          return this.newSelectedDungeon
        }
      }
    },
    IsPlayerLobbyLeader(){
      let isLeader = false
      if(this.playerLobby){

          this.playerLobby.players.forEach((player) => {
            if(player.identifier == this.playerIdentifier) {
              isLeader = player.isLeader
            }
          })
    
      }
      return isLeader
    },  
  },
  watch:{
    newLobbyMaxPlayersAmount(newVal, oldVal){
      console.log("newVal, oldVal : ", newVal, oldVal)  
      if(isNaN(newVal)) {
        this.newLobbyMaxPlayersAmount = 1
      }
      if(newVal <= 0){
        this.newLobbyMaxPlayersAmount = oldVal
      }
      if(newVal > 4){
        this.newLobbyMaxPlayersAmount = oldVal
      }
    } 
  },
})

$(function () {
  window.onload = (e) => {
    window.addEventListener("message", (event) => {

      let item = event.data;
      switch (item.type) {
        case "SET_PLAYER_IDENTIFIER":
          APP.SetPlayerIdentifier(item.identifer)
          break
        case "SET_PLAYER_LOBBY":
          APP.SetPlayerLobby(item.playerLobby, item.inLobby)
          break
        case "SET_LOBBIES":
          APP.SetLobbies(item.lobbies)
          break
        case "SET_DUNGEONS":
          APP.SetDungeons(item.dungeons)
          break
        case "OPEN_UI":
          APP.OpenUI()
          break  
        case "CLOSE_UI":
          APP.CloseUI()
          break  
        case "SEND_LOCALIZATION":
          APP.SetLocalization(item.localization)  
          break
        default:
          break
      }

      if (item.type == "showHealth") {
        document.querySelector(".healthbar").style.display = "block";

        let health = Number(item.health);
        let maxHealth = Number(item.maxHealth)
        let percentage = (health / maxHealth) * 100
        document.querySelector(".health-progress").style.backgroundColor = 'hsl(135, 100%, 24%)';

        document.querySelector(".health-progress").style.width = percentage + "%";

      } else if (item.type == "hideHealth") {
        document.querySelector(".healthbar").style.display = "none";
        document.querySelector(".health-progress").style.backgroundColor = 'hsl(135, 100%, 24%)';

        document.querySelector(".health-progress").style.transition =
          "all linear 0.3s";
        document.querySelector(".health-progress").style.width = "0";
      } else if (item.type == "redColor") {
        document.querySelector(".health-progress").style.backgroundColor = 'hsl(0, 100%, 24%)';
        document.querySelector(".health-progress").style.transition = "none";
        document.querySelector(".health-progress").style.width = 100 + "%";
      }
    });
  };
});
