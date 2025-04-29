<script setup>

import { ref, onMounted, onUnmounted } from 'vue';

// const getRandomNumber = () => {
//   let number = Math.floor(Math.random() * 100) + 1;
//   return number;
// };

const number = ref(10);

function incrementNumber() {
  number.value += 1;
}



onMounted(() => {
  let intervalId = setInterval(() => {
    // number.value -= 1;
    if (number.value > 0) {
      number.value -= 1;
    }// Decrease by 1 every second
    
  }, 500); //500 mmillisecond interval
});

// Clean up the interval when component is destroyed
onUnmounted(() => {
  clearInterval(intervalId);
});
 



</script>

<template>

  <body>
    <div class="container">

      <img src="./assets/PulsePoint.svg" alt="Vue logo" class="logo" />



      <p>{{number}}</p>

      <button @click="incrementNumber">Click Me</button>

      <Teleport>
        <p v-if="number >= 100" class="popupMessage">Congratulations Pleb</p>
        <p v-if="number == 0" class="popupMessage">Tough Luck Buddy</p>
      </Teleport>



    </div>
  </body>



</template>


